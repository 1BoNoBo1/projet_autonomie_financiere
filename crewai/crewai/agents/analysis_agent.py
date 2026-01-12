"""
Agent d'analyse financière
"""
import os
from crewai import Agent
from crewai.tools import get_analysis_tools


def create_analysis_agent() -> Agent:
    """
    Crée un agent spécialisé dans l'analyse financière
    
    Returns:
        Agent: Agent d'analyse configuré
    """
    return Agent(
        role="Analyste Financier",
        goal="Analyser en profondeur les opportunités financières et évaluer leur viabilité",
        backstory="""Tu es un analyste financier expérimenté avec une expertise en évaluation
        de projets, analyse de risques, et prévisions financières. Tu es méthodique et précis,
        et tu bases tes analyses sur des données concrètes. Tu évalues chaque opportunité
        sous plusieurs angles : rentabilité, risques, évolutivité, et faisabilité technique.
        Tu fournis des analyses détaillées avec des recommandations claires.""",
        verbose=True,
        allow_delegation=False,
        tools=get_analysis_tools(),
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
