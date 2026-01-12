"""
Outils de recherche pour l'agent de recherche
"""
from crewai import Tool
from langchain_community.tools import DuckDuckGoSearchRun
import requests
import os


def web_search(query: str) -> str:
    """
    Effectue une recherche web sur un sujet donné
    
    Args:
        query: La requête de recherche
        
    Returns:
        str: Résultats de la recherche
    """
    try:
        search = DuckDuckGoSearchRun()
        results = search.run(query)
        return results
    except Exception as e:
        return f"Erreur lors de la recherche: {str(e)}"


def get_research_tools():
    """
    Retourne la liste des outils de recherche
    
    Returns:
        list: Liste des outils de recherche
    """
    return [
        Tool(
            name="WebSearch",
            func=web_search,
            description="Recherche d'informations sur Internet. Utilise cet outil pour rechercher des opportunités financières, des tendances du marché, des nouvelles technologies, etc."
        ),
        Tool(
            name="MarketAnalysis",
            func=analyze_market,
            description="Analyse les tendances du marché et identifie les opportunités émergentes"
        )
    ]


def analyze_market(topic: str) -> str:
    """
    Analyse les tendances du marché pour un sujet donné
    
    Args:
        topic: Le sujet à analyser
        
    Returns:
        str: Analyse du marché
    """
    # Pour l'instant, utilise la recherche web
    # Plus tard, on pourra intégrer des APIs spécialisées
    search = DuckDuckGoSearchRun()
    results = search.run(f"market trends {topic} 2024 2025")
    return f"Analyse du marché pour '{topic}':\n{results}"
