"""
Outils pour interagir avec des APIs externes
"""
from crewai import Tool
import requests
import os
import json


def call_openrouter_api(prompt: str, model: str = None) -> str:
    """
    Appelle l'API OpenRouter pour une requête personnalisée
    
    Args:
        prompt: Le prompt à envoyer
        model: Le modèle à utiliser (optionnel)
        
    Returns:
        str: Réponse de l'API
    """
    try:
        api_key = os.getenv("OPENROUTER_API_KEY")
        base_url = os.getenv("OPENROUTER_BASE_URL", "https://openrouter.ai/api/v1")
        model = model or os.getenv("OPENROUTER_DEFAULT_MODEL", "openai/gpt-4-turbo")
        
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }
        
        data = {
            "model": model,
            "messages": [
                {"role": "user", "content": prompt}
            ]
        }
        
        response = requests.post(
            f"{base_url}/chat/completions",
            headers=headers,
            json=data,
            timeout=60
        )
        
        if response.status_code == 200:
            result = response.json()
            return result.get("choices", [{}])[0].get("message", {}).get("content", "")
        else:
            return f"Erreur API: {response.status_code} - {response.text}"
            
    except Exception as e:
        return f"Erreur lors de l'appel API: {str(e)}"


def get_api_tools():
    """
    Retourne la liste des outils API
    
    Returns:
        list: Liste des outils API
    """
    return [
        Tool(
            name="CallOpenRouterAPI",
            func=call_openrouter_api,
            description="Appelle l'API OpenRouter pour des requêtes personnalisées. Utile pour des analyses approfondies ou des générations de contenu."
        )
    ]
