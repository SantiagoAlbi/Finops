import json
import boto3
import os
from datetime import datetime, timedelta

# Clientes AWS
ec2_client = boto3.client('ec2')
elb_client = boto3.client('elbv2')
rds_client = boto3.client('rds')
sns_client = boto3.client('sns')

# Variables de entorno
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']
SNAPSHOT_AGE_DAYS = int(os.environ.get('SNAPSHOT_AGE_DAYS', 30))


def lambda_handler(event, context):
    """
    Función principal que detecta recursos sin usar
    """
    print("🔍 Iniciando escaneo de recursos sin usar...")
    
    unused_resources = {
        'ebs_volumes': find_unattached_volumes(),
        'elastic_ips': find_unassigned_eips(),
        'load_balancers': find_unused_load_balancers(),
        'rds_snapshots': find_old_snapshots()
    }
    
    # Contar total de recursos
    total_unused = sum(len(resources) for resources in unused_resources.values())
    
    if total_unused > 0:
        send_unused_resources_alert(unused_resources, total_unused)
        print(f"⚠️  {total_unused} recursos sin usar detectados y alertados")
    else:
        print("✅ No se encontraron recursos sin usar")
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'total_unused': total_unused,
            'details': {k: len(v) for k, v in unused_resources.items()}
        })
    }


def find_unattached_volumes():
    """
    Encuentra EBS volumes que no están attachados a ninguna instancia
    """
    print("📦 Buscando EBS volumes sin attachar...")
    
    response = ec2_client.describe_volumes(
        Filters=[
            {'Name': 'status', 'Values': ['available']}
        ]
    )
    
    unattached = []
    for volume in response['Volumes']:
        size_gb = volume['Size']
        volume_type = volume['VolumeType']
        created = volume['CreateTime'].strftime('%Y-%m-%d')
        
        # Calcular costo mensual aproximado
        cost = calculate_ebs_cost(size_gb, volume_type)
        
        unattached.append({
            'id': volume['VolumeId'],
            'size': f"{size_gb} GB",
            'type': volume_type,
            'created': created,
            'monthly_cost': f"${cost:.2f}"
        })
    
    print(f"   Encontrados: {len(unattached)} volumes")
    return unattached


def find_unassigned_eips():
    """
    Encuentra Elastic IPs que no están asignadas a ninguna instancia
    """
    print("🌐 Buscando Elastic IPs sin asignar...")
    
    response = ec2_client.describe_addresses()
    
    unassigned = []
    for address in response['Addresses']:
        # Si no tiene InstanceId ni NetworkInterfaceId, está sin usar
        if 'InstanceId' not in address and 'NetworkInterfaceId' not in address:
            unassigned.append({
                'ip': address['PublicIp'],
                'allocation_id': address['AllocationId'],
                'monthly_cost': "$3.60"  # EIP sin usar cuesta $0.005/hora = $3.60/mes
            })
    
    print(f"   Encontradas: {len(unassigned)} IPs")
    return unassigned


def find_unused_load_balancers():
    """
    Encuentra Load Balancers sin targets registrados
    """
    print("⚖️  Buscando Load Balancers sin targets...")
    
    response = elb_client.describe_load_balancers()
    
    unused = []
    for lb in response['LoadBalancers']:
        lb_arn = lb['LoadBalancerArn']
        lb_name = lb['LoadBalancerName']
        lb_type = lb['Type']
        
        # Obtener target groups
        tg_response = elb_client.describe_target_groups(LoadBalancerArn=lb_arn)
        
        has_targets = False
        for tg in tg_response['TargetGroups']:
            # Verificar si hay targets registrados
            health = elb_client.describe_target_health(TargetGroupArn=tg['TargetGroupArn'])
            if health['TargetHealthDescriptions']:
                has_targets = True
                break
        
        if not has_targets:
            # Calcular costo aproximado
            cost = 22.0 if lb_type == 'application' else 20.0  # ALB vs NLB
            
            unused.append({
                'name': lb_name,
                'type': lb_type,
                'dns': lb['DNSName'],
                'monthly_cost': f"${cost:.2f}"
            })
    
    print(f"   Encontrados: {len(unused)} load balancers")
    return unused


def find_old_snapshots():
    """
    Encuentra RDS snapshots manuales mayores a X días
    """
    print("💾 Buscando RDS snapshots antiguos...")
    
    response = rds_client.describe_db_snapshots(
        SnapshotType='manual'
    )
    
    cutoff_date = datetime.now() - timedelta(days=SNAPSHOT_AGE_DAYS)
    
    old_snapshots = []
    for snapshot in response['DBSnapshots']:
        created = snapshot['SnapshotCreateTime'].replace(tzinfo=None)
        
        if created < cutoff_date:
            age_days = (datetime.now() - created).days
            size_gb = snapshot['AllocatedStorage']
            
            # Costo: $0.095 por GB-mes
            monthly_cost = size_gb * 0.095
            
            old_snapshots.append({
                'id': snapshot['DBSnapshotIdentifier'],
                'db_instance': snapshot['DBInstanceIdentifier'],
                'age_days': age_days,
                'size': f"{size_gb} GB",
                'created': created.strftime('%Y-%m-%d'),
                'monthly_cost': f"${monthly_cost:.2f}"
            })
    
    print(f"   Encontrados: {len(old_snapshots)} snapshots")
    return old_snapshots


def calculate_ebs_cost(size_gb, volume_type):
    """
    Calcula costo mensual aproximado de un EBS volume
    Precios en us-east-1
    """
    costs_per_gb = {
        'gp2': 0.10,
        'gp3': 0.08,
        'io1': 0.125,
        'io2': 0.125,
        'st1': 0.045,
        'sc1': 0.025,
        'standard': 0.05
    }
    
    price = costs_per_gb.get(volume_type, 0.10)
    return size_gb * price


def send_unused_resources_alert(resources, total):
    """
    Envía alerta a SNS con recursos sin usar
    """
    message_lines = [
        "🗑️  ALERTA: RECURSOS SIN USAR DETECTADOS",
        "",
        f"Total de recursos: {total}",
        ""
    ]
    
    # EBS Volumes
    if resources['ebs_volumes']:
        message_lines.append(f"📦 EBS Volumes sin attachar ({len(resources['ebs_volumes'])}):")
        for vol in resources['ebs_volumes'][:5]:  # Máximo 5
            message_lines.append(
                f"  • {vol['id']} - {vol['size']} {vol['type']} - {vol['monthly_cost']}/mes"
            )
        if len(resources['ebs_volumes']) > 5:
            message_lines.append(f"  ... y {len(resources['ebs_volumes']) - 5} más")
        message_lines.append("")
    
    # Elastic IPs
    if resources['elastic_ips']:
        message_lines.append(f"🌐 Elastic IPs sin asignar ({len(resources['elastic_ips'])}):")
        for eip in resources['elastic_ips'][:5]:
            message_lines.append(f"  • {eip['ip']} - {eip['monthly_cost']}/mes")
        if len(resources['elastic_ips']) > 5:
            message_lines.append(f"  ... y {len(resources['elastic_ips']) - 5} más")
        message_lines.append("")
    
    # Load Balancers
    if resources['load_balancers']:
        message_lines.append(f"⚖️  Load Balancers sin targets ({len(resources['load_balancers'])}):")
        for lb in resources['load_balancers']:
            message_lines.append(f"  • {lb['name']} ({lb['type']}) - {lb['monthly_cost']}/mes")
        message_lines.append("")
    
    # RDS Snapshots
    if resources['rds_snapshots']:
        message_lines.append(f"💾 RDS Snapshots antiguos ({len(resources['rds_snapshots'])}):")
        for snap in resources['rds_snapshots'][:5]:
            message_lines.append(
                f"  • {snap['id']} - {snap['age_days']} días - {snap['size']} - {snap['monthly_cost']}/mes"
            )
        if len(resources['rds_snapshots']) > 5:
            message_lines.append(f"  ... y {len(resources['rds_snapshots']) - 5} más")
        message_lines.append("")
    
    # Calcular ahorro potencial
    total_cost = sum_monthly_costs(resources)
    message_lines.extend([
        f"💰 Ahorro potencial: ${total_cost:.2f}/mes",
        "",
        "Revisa estos recursos y elimina los que no necesites."
    ])
    
    message = "\n".join(message_lines)
    
    try:
        sns_client.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=f"🗑️  {total} Recursos sin usar detectados",
            Message=message
        )
        print("📧 Alerta enviada a SNS")
    except Exception as e:
        print(f"❌ Error enviando alerta: {e}")


def sum_monthly_costs(resources):
    """
    Suma todos los costos mensuales de recursos sin usar
    """
    total = 0.0
    
    for category in resources.values():
        for resource in category:
            cost_str = resource.get('monthly_cost', '$0.00')
            # Extraer número del string "$X.XX"
            cost = float(cost_str.replace('$', ''))
            total += cost
    
    return total
