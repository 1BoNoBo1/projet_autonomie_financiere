"""
Agent de prise de décision
"""
import os
from crewai.agent import Agent
from crewai.tools import get_decision_tools


def create_decision_agent() -> Agent:
    """
    Crée un agent spécialisé dans la prise de décision
    
    Returns:
        Agent: Agent de décision configuré
    """
    return Agent(
        role="Preneur de Décision Stratégique",
        goal="Prendre des décisions éclairées basées sur les recherches et analyses",
        backstory="""Tu es un décideur stratégique expérimenté qui prend des décisions
        importantes basées sur des données et analyses. Tu es capable de synthétiser
        des informations complexes et de prendre des décisions rapides mais réfléchies.
        Tu comprends les enjeux de l'autonomie financière et tu es prêt à prendre des risques
        calculés pour atteindre cet objectif. Tu priorises les actions qui ont le plus
        d'impact et le meilleur retour sur investissement.""",
        verbose=True,
        allow_delegation=False,
        tools=get_decision_tools(),
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
