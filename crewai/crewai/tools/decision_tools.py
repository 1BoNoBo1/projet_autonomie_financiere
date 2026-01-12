"""
Outils de décision pour l'agent de décision
"""
from crewai import Tool
try:
    from crewai.tools.n8n_tools import trigger_n8n_workflow
except ImportError:
    def trigger_n8n_workflow(*args, **kwargs):
        return "n8n tools non disponibles"
import json
from datetime import datetime


def make_decision(criteria: str, options: str) -> str:
    """
    Prend une décision basée sur des critères et options
    
    Args:
        criteria: Critères de décision
        options: Options disponibles (format JSON ou texte)
        
    Returns:
        str: Décision prise avec justification
    """
    try:
        # Essayer de parser les options comme JSON
        if isinstance(options, str):
            try:
                options_parsed = json.loads(options)
            except:
                options_parsed = options
        else:
            options_parsed = options
        
        # Analyse basique (sera améliorée avec le LLM)
        decision = f"Décision prise le {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
        decision += f"Critères: {criteria}\n"
        decision += f"Options analysées: {options_parsed}\n"
        decision += "Recommandation: Analysez les options en fonction des critères fournis."
        
        return decision
    except Exception as e:
        return f"Erreur lors de la prise de décision: {str(e)}"


def create_action_plan(goal: str, steps: str) -> str:
    """
    Crée un plan d'action pour atteindre un objectif
    
    Args:
        goal: Objectif à atteindre
        steps: Étapes à suivre
        
    Returns:
        str: Plan d'action formaté
    """
    plan = f"Plan d'action pour: {goal}\n"
    plan += f"Créé le: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n"
    plan += "Étapes:\n"
    
    if isinstance(steps, str):
        try:
            steps_parsed = json.loads(steps)
            if isinstance(steps_parsed, list):
                for i, step in enumerate(steps_parsed, 1):
                    plan += f"{i}. {step}\n"
            else:
                plan += steps
        except:
            plan += steps
    else:
        plan += str(steps)
    
    return plan


def execute_decision(decision: str, action: str) -> str:
    """
    Exécute une décision en déclenchant les actions nécessaires
    
    Args:
        decision: La décision prise
        action: L'action à exécuter
        
    Returns:
        str: Résultat de l'exécution
    """
    try:
        # Pour l'instant, on peut déclencher un workflow n8n
        # ou enregistrer la décision pour exécution ultérieure
        result = f"Décision exécutée: {decision}\n"
        result += f"Action: {action}\n"
        result += f"Timestamp: {datetime.now().isoformat()}\n"
        
        # Optionnel: déclencher un workflow n8n
        # trigger_n8n_workflow("execute_decision", {"decision": decision, "action": action})
        
        return result
    except Exception as e:
        return f"Erreur lors de l'exécution: {str(e)}"


def get_decision_tools():
    """
    Retourne la liste des outils de décision
    
    Returns:
        list: Liste des outils de décision
    """
    return [
        Tool(
            name="MakeDecision",
            func=make_decision,
            description="Prend une décision basée sur des critères et options. Utilise cet outil pour choisir entre plusieurs opportunités ou stratégies."
        ),
        Tool(
            name="CreateActionPlan",
            func=create_action_plan,
            description="Crée un plan d'action détaillé pour atteindre un objectif. Utile pour planifier l'exécution d'une décision."
        ),
        Tool(
            name="ExecuteDecision",
            func=execute_decision,
            description="Exécute une décision en déclenchant les actions nécessaires. Peut déclencher des workflows n8n ou d'autres automatisations."
        )
    ]
