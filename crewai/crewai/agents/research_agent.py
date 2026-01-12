"""
Agent de recherche d'opportunités financières
"""
import os
from crewai import Agent
from crewai.tools import get_research_tools


def create_research_agent() -> Agent:
    """
    Crée un agent spécialisé dans la recherche d'opportunités financières
    
    Returns:
        Agent: Agent de recherche configuré
    """
    return Agent(
        role="Chercheur d'Opportunités Financières",
        goal="Rechercher et identifier les meilleures opportunités pour atteindre l'autonomie financière",
        backstory="""Tu es un expert en recherche d'opportunités financières. 
        Tu es spécialisé dans l'identification de revenus passifs, d'investissements rentables,
        et de stratégies d'automatisation qui peuvent générer des revenus récurrents.
        Tu analyses constamment le marché, les tendances, et les nouvelles technologies
        pour trouver des opportunités que d'autres pourraient manquer.""",
        verbose=True,
        allow_delegation=False,
        tools=get_research_tools(),
        llm=create_llm()
    )


def create_llm():
    """Crée le LLM configuré avec OpenRouter"""
    from langchain_openai import ChatOpenAI
    
    openrouter_api_key = os.getenv("OPENROUTER_API_KEY")
    openrouter_base_url = os.getenv("OPENROUTER_BASE_URL", "https://openrouter.ai/api/v1")
    model = os.getenv("OPENROUTER_DEFAULT_MODEL", "openai/gpt-4-turbo")
    temperature = float(os.getenv("CREWAI_TEMPERATURE", "0.7"))
    
    return ChatOpenAI(
        model=model,
        base_url=openrouter_base_url,
        api_key=openrouter_api_key,
        temperature=temperature,
        timeout=60,
        max_retries=3
    )
