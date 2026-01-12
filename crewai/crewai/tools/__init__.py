"""
Outils pour les agents CrewAI
"""
from crewai.tools.research_tools import get_research_tools
from crewai.tools.analysis_tools import get_analysis_tools
from crewai.tools.decision_tools import get_decision_tools
from crewai.tools.n8n_tools import get_n8n_tools
from crewai.tools.api_tools import get_api_tools

__all__ = [
    "get_research_tools",
    "get_analysis_tools",
    "get_decision_tools",
    "get_n8n_tools",
    "get_api_tools",
    "get_available_tools"
]


def get_available_tools():
    """Retourne tous les outils disponibles"""
    all_tools = []
    all_tools.extend(get_research_tools())
    all_tools.extend(get_analysis_tools())
    all_tools.extend(get_decision_tools())
    all_tools.extend(get_n8n_tools())
    all_tools.extend(get_api_tools())
    return all_tools
