# Cadastro de Cliente Corporativo

Projeto Salesforce desenvolvido para cadastro e atualização de clientes corporativos com consulta de CNPJ na API ReceitaWS.

## Solução
A solução foi implementada com arquitetura híbrida:
- `LWC` como interface principal do usuário
- `Apex` para integração e regras de negócio
- `Screen Flow` como automação complementar

## Principais Recursos
- consulta de CNPJ
- validação de CNPJ
- identificação de empresa já cadastrada
- preenchimento automático dos dados
- criação e atualização de `Account`
- controle de acesso por `Permission Set`
- app exclusiva para o processo de cadastro

## Estrutura Principal
- `ReceitaWSService.cls`: integração com a ReceitaWS e persistência
- `ReceitaWSFlowAction.cls`: ação de busca para o Flow
- `ReceitaWSSaveFlowAction.cls`: ação de salvamento para o Flow
- `cnpjSearch`: LWC principal da tela de cadastro

## Documentação
A documentação complementar está em:
- `docs/especificacao-tecnica.md`

## Observações
A API pública da ReceitaWS possui limitações de uso gratuito. Por esse motivo, os testes devem ser realizados com moderação para evitar bloqueios temporários.
