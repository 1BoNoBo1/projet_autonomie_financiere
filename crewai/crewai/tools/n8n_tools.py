"""
Outils pour interagir avec n8n
"""
from crewai import Tool
import requests
import os
import json


def trigger_n8n_workflow(workflow_name: str, data: dict = None) -> str:
    """
    Déclenche un workflow n8n
    
    Args:
        workflow_name: Nom du workflow à déclencher
        data: Données à envoyer au workflow
        
    Returns:
        str: Résultat de l'exécution du workflow
    """
    try:
        n8n_url = os.getenv("N8N_WEBHOOK_URL", "http://n8n:5678")
        n8n_user = os.getenv("N8N_BASIC_AUTH_USER", "admin")
        n8n_password = os.getenv("N8N_BASIC_AUTH_PASSWORD", "")
        
        # Construire l'URL du webhook
        webhook_url = f"{n8n_url}/webhook/{workflow_name}"
        
        # Faire la requête
        response = requests.post(
            webhook_url,
            json=data or {},
            auth=(n8n_user, n8n_password) if n8n_user and n8n_password else None,
            timeout=30
        )
        
        if response.status_code == 200:
            return f"Workflow '{workflow_name}' déclenché avec succès. Réponse: {response.text}"
        else:
            return f"Erreur lors du déclenchement du workflow: {response.status_code} - {response.text}"
            
    except requests.exceptions.RequestException as e:
        return f"Erreur de connexion à n8n: {str(e)}"
    except Exception as e:
        return f"Erreur lors du déclenchement du workflow: {str(e)}"


def get_n8n_workflow_status(workflow_name: str) -> str:
    """
    Récupère le statut d'un workflow n8n
    
    Args:
        workflow_name: Nom du workflow
        
    Returns:
        str: Statut du workflow
    """
    try:
        n8n_url = os.getenv("N8N_WEBHOOK_URL", "http://n8n:5678")
        n8n_user = os.getenv("N8N_BASIC_AUTH_USER", "admin")
        n8n_password = os.getenv("N8N_BASIC_AUTH_PASSWORD", "")
        
        # Note: Cette fonction nécessiterait une API n8n pour récupérer le statut
        # Pour l'instant, on retourne une réponse basique
        return f"Workflow '{workflow_name}': Statut non disponible (nécessite API n8n)"
        
    except Exception as e:
        return f"Erreur lors de la récupération du statut: {str(e)}"


def get_n8n_tools():
    """
    Retourne la liste des outils n8n
    
    Returns:
        list: Liste des outils n8n
    """
    return [
        Tool(
            name="TriggerN8NWorkflow",
            func=trigger_n8n_workflow,
            description="Déclenche un workflow n8n. Utilise cet outil pour automatiser des actions basées sur les décisions prises."
        ),
        Tool(
            name="GetN8NWorkflowStatus",
            func=get_n8n_workflow_status,
            description="Récupère le statut d'un workflow n8n. Utile pour vérifier l'état d'exécution d'une automatisation."
        )
    ]
