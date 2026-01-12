"""
Outils d'analyse pour l'agent d'analyse
"""
from crewai import Tool
import json
from typing import Dict, Any


def calculate_roi(investment: float, returns: float, period: str = "annuel") -> str:
    """
    Calcule le retour sur investissement (ROI)
    
    Args:
        investment: Montant de l'investissement
        returns: Retours attendus
        period: Période (annuel, mensuel, etc.)
        
    Returns:
        str: Calcul du ROI formaté
    """
    try:
        roi = ((returns - investment) / investment) * 100
        return f"ROI {period}: {roi:.2f}% (Investissement: {investment}€, Retours: {returns}€)"
    except Exception as e:
        return f"Erreur dans le calcul du ROI: {str(e)}"


def analyze_financial_data(data: str) -> str:
    """
    Analyse des données financières
    
    Args:
        data: Données financières au format JSON ou texte
        
    Returns:
        str: Analyse des données
    """
    try:
        # Essayer de parser comme JSON
        if isinstance(data, str):
            parsed_data = json.loads(data)
        else:
            parsed_data = data
        
        analysis = f"Analyse des données financières:\n"
        analysis += f"- Nombre d'éléments: {len(parsed_data) if isinstance(parsed_data, (list, dict)) else 1}\n"
        analysis += f"- Type de données: {type(parsed_data).__name__}\n"
        
        return analysis
    except json.JSONDecodeError:
        return f"Analyse des données (format texte):\n{data[:500]}"
    except Exception as e:
        return f"Erreur lors de l'analyse: {str(e)}"


def evaluate_risk(factors: str) -> str:
    """
    Évalue les risques d'une opportunité
    
    Args:
        factors: Facteurs de risque à évaluer
        
    Returns:
        str: Évaluation des risques
    """
    # Analyse basique des risques
    risk_keywords = {
        "high": ["élevé", "important", "significatif", "grand", "haut"],
        "medium": ["moyen", "modéré", "acceptable"],
        "low": ["faible", "minimal", "réduit", "bas"]
    }
    
    factors_lower = factors.lower()
    risk_level = "medium"
    
    for level, keywords in risk_keywords.items():
        if any(keyword in factors_lower for keyword in keywords):
            risk_level = level
            break
    
    return f"Évaluation des risques: {risk_level.upper()}\nFacteurs analysés: {factors}"


def get_analysis_tools():
    """
    Retourne la liste des outils d'analyse
    
    Returns:
        list: Liste des outils d'analyse
    """
    return [
        Tool(
            name="CalculateROI",
            func=calculate_roi,
            description="Calcule le retour sur investissement (ROI) pour un investissement donné. Utile pour évaluer la rentabilité d'une opportunité."
        ),
        Tool(
            name="AnalyzeFinancialData",
            func=analyze_financial_data,
            description="Analyse des données financières. Accepte du JSON ou du texte. Utile pour analyser les performances, les revenus, etc."
        ),
        Tool(
            name="EvaluateRisk",
            func=evaluate_risk,
            description="Évalue les risques d'une opportunité financière. Prend en compte les facteurs de risque et retourne une évaluation."
        )
    ]
