import json
import boto3
import os
from datetime import datetime, timedelta
from decimal import Decimal

# Clientes AWS
ce_client = boto3.client('ce')  # Cost Explorer
dynamodb = boto3.resource('dynamodb')
sns_client = boto3.client('sns')

# Variables de entorno (vienen de Terraform)
TABLE_NAME = os.environ['DYNAMODB_TABLE']
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']
THRESHOLD = int(os.environ['ANOMALY_THRESHOLD'])
HISTORICAL_DAYS = int(os.environ['HISTORICAL_DAYS'])

table = dynamodb.Table(TABLE_NAME)


def lambda_handler(event, context):
    """
    Función principal que se ejecuta cuando EventBridge activa la Lambda
    """
    print("🚀 Iniciando detección de anomalías de costos...")
    
    # 1. Obtener costos de hoy
    today_costs = get_today_costs()
    print(f"📊 Costos de hoy: {today_costs}")
    
    # 2. Obtener costos históricos (últimos N días)
    historical_costs = get_historical_costs()
    print(f"📈 Costos históricos: {historical_costs}")
    
    # 3. Detectar anomalías
    anomalies = detect_anomalies(today_costs, historical_costs)
    
    # 4. Guardar en DynamoDB
    save_to_dynamodb(today_costs)
    
    # 5. Enviar alertas si hay anomalías
    if anomalies:
        send_alert(anomalies)
        print(f"⚠️  {len(anomalies)} anomalías detectadas y alertadas")
    else:
        print("✅ No se detectaron anomalías")
     
        # Publicar métricas custom
    publish_custom_metric('AnomaliesDetected', len(anomalies))
    publish_custom_metric('ServicesChecked', len(today_costs))
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'anomalies_detected': len(anomalies),
            'services_checked': len(today_costs)
        })
    }


def get_today_costs():
    """
    Consulta Cost Explorer para obtener costos de HOY por servicio
    
    Retorna: dict con formato {"EC2": 45.67, "RDS": 23.45, ...}
    """
    today = datetime.now().date()
    tomorrow = today + timedelta(days=1)
    
    response = ce_client.get_cost_and_usage(
        TimePeriod={
            'Start': str(today),
            'End': str(tomorrow)
        },
        Granularity='DAILY',
        Metrics=['UnblendedCost'],
        GroupBy=[
            {
                'Type': 'DIMENSION',
                'Key': 'SERVICE'
            }
        ]
    )
    
    # Parsear respuesta de Cost Explorer
    costs = {}
    for result in response['ResultsByTime']:
        for group in result['Groups']:
            service = group['Keys'][0]
            cost = float(group['Metrics']['UnblendedCost']['Amount'])
            
            # Solo guardar si el costo > $0.01 (ignorar centavos)
            if cost > 0.01:
                costs[service] = round(cost, 2)
    
    return costs


def get_historical_costs():
    """
    Consulta Cost Explorer para obtener costos de últimos N días por servicio
    Calcula el PROMEDIO de cada servicio
    
    Retorna: dict con formato {"EC2": 38.50, "RDS": 20.30, ...}
    """
    end_date = datetime.now().date()
    start_date = end_date - timedelta(days=HISTORICAL_DAYS)
    
    response = ce_client.get_cost_and_usage(
        TimePeriod={
            'Start': str(start_date),
            'End': str(end_date)
        },
        Granularity='DAILY',
        Metrics=['UnblendedCost'],
        GroupBy=[
            {
                'Type': 'DIMENSION',
                'Key': 'SERVICE'
            }
        ]
    )
    
    # Sumar costos por servicio
    service_totals = {}
    service_counts = {}
    
    for result in response['ResultsByTime']:
        for group in result['Groups']:
            service = group['Keys'][0]
            cost = float(group['Metrics']['UnblendedCost']['Amount'])
            
            if cost > 0.01:
                service_totals[service] = service_totals.get(service, 0) + cost
                service_counts[service] = service_counts.get(service, 0) + 1
    
    # Calcular promedios
    averages = {}
    for service, total in service_totals.items():
        averages[service] = round(total / service_counts[service], 2)
    
    return averages


def detect_anomalies(today_costs, historical_costs):
    """
    Compara costos de hoy vs promedio histórico
    Detecta anomalías si: today_cost > (historical_avg * (1 + THRESHOLD/100))
    
    Retorna: lista de anomalías detectadas
    """
    anomalies = []
    
    for service, today_cost in today_costs.items():
        # Si el servicio no tiene histórico, no podemos comparar
        if service not in historical_costs:
            continue
        
        historical_avg = historical_costs[service]
        
        # Calcular % de incremento
        increase_pct = ((today_cost - historical_avg) / historical_avg) * 100
        
        # Si supera el umbral → anomalía
        if increase_pct > THRESHOLD:
            anomalies.append({
                'service': service,
                'today_cost': today_cost,
                'historical_avg': historical_avg,
                'increase_pct': round(increase_pct, 1),
                'difference': round(today_cost - historical_avg, 2)
            })
    
    # Ordenar por mayor incremento
    anomalies.sort(key=lambda x: x['increase_pct'], reverse=True)
    
    return anomalies


def save_to_dynamodb(costs):
    """
    Guarda costos en DynamoDB para histórico
    
    Estructura:
    - date_service: "2024-12-15#EC2" (partition key)
    - timestamp: 1734278400 (sort key)
    - service: "EC2"
    - cost: 45.67
    - ttl: 1739462400 (60 días después)
    """
    today = datetime.now()
    timestamp = int(today.timestamp())
    date_str = today.strftime('%Y-%m-%d')
    
    # TTL: 60 días desde hoy
    ttl = int((today + timedelta(days=60)).timestamp())
    
    for service, cost in costs.items():
        try:
            table.put_item(
                Item={
                    'date_service': f"{date_str}#{service}",
                    'timestamp': timestamp,
                    'service': service,
                    'cost': Decimal(str(cost)),
                    'currency': 'USD',
                    'ttl': ttl
                }
            )
        except Exception as e:
            print(f"❌ Error guardando {service} en DynamoDB: {e}")


def send_alert(anomalies):
    """
    Envía alerta a SNS con las anomalías detectadas
    """
    # Construir mensaje
    message_lines = [
        "🚨 ALERTA DE ANOMALÍA DE COSTOS 🚨",
        "",
        f"Se detectaron {len(anomalies)} servicios con costos anormales:",
        ""
    ]
    
    for anomaly in anomalies:
        message_lines.append(
            f"• {anomaly['service']}: "
            f"${anomaly['today_cost']} (↑{anomaly['increase_pct']}% vs promedio ${anomaly['historical_avg']})"
        )
    
    message_lines.extend([
        "",
        f"Umbral de alerta: {THRESHOLD}%",
        f"Período de comparación: últimos {HISTORICAL_DAYS} días",
        "",
        "Revisa tu cuenta AWS para más detalles."
    ])
    
    message = "\n".join(message_lines)
    
    # Enviar a SNS
    try:
        sns_client.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=f"⚠️ Anomalía de Costos: {len(anomalies)} servicios afectados",
            Message=message
        )
        print("📧 Alerta enviada a SNS")
    except Exception as e:
        print(f"❌ Error enviando alerta: {e}")

def publish_custom_metric(metric_name, value, unit='Count'):
    """
    Publica métrica custom a CloudWatch
    """
    cloudwatch = boto3.client('cloudwatch')
    
    try:
        cloudwatch.put_metric_data(
            Namespace='FinOps/Platform',
            MetricData=[
                {
                    'MetricName': metric_name,
                    'Value': value,
                    'Unit': unit,
                    'Timestamp': datetime.now()
                }
            ]
        )
    except Exception as e:
        print(f"Error publicando métrica: {e}")
