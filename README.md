# Cadastro de Cliente Corporativo

Projeto Salesforce desenvolvido para cadastro e atualizacao de clientes corporativos com consulta de CNPJ na API ReceitaWS.

## Solucao
A solucao foi implementada com arquitetura hibrida:
- `LWC` como interface principal do usuario
- `Apex` para integracao e regras de negocio
- `Screen Flow` como automacao complementar

## Principais Recursos
- consulta de CNPJ
- validacao de CNPJ
- identificacao de empresa ja cadastrada
- preenchimento automatico dos dados
- criacao e atualizacao de `Account`
- controle de acesso por `Permission Set`
- app exclusiva para o processo de cadastro

## Estrutura Principal
- `ReceitaWSService.cls`: integracao com ReceitaWS e persistencia
- `ReceitaWSFlowAction.cls`: acao de busca para Flow
- `ReceitaWSSaveFlowAction.cls`: acao de salvamento para Flow
- `cnpjSearch`: LWC principal da tela de cadastro

## Documentacao
A documentacao complementar esta em:
- `docs/especificacao-tecnica.md`
- `docs/checklist-projeto.md`

## Observacoes
A API publica da ReceitaWS possui limitacoes de uso gratuito, portanto os testes devem ser realizados com moderacao para evitar bloqueios temporarios.
