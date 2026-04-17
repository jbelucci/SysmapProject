# Especificação Técnica - Cadastro de Cliente Corporativo

## 1. Objetivo
Este documento descreve a solução implementada para o processo de cadastro e atualização de clientes corporativos no Salesforce, com consulta de CNPJ na API ReceitaWS, preenchimento automático dos dados da empresa, controle de acesso por perfil e permission set e experiência principal em Lightning Web Component (LWC).

## 2. Visão Geral da Solução
A solução foi estruturada em arquitetura híbrida, composta por:
- `LWC` como interface principal do usuário
- `Apex` para integração com a ReceitaWS e regras de negócio
- `Screen Flow` como automação complementar do processo

A aplicação principal foi criada com o nome `Cadastro de Cliente Corporativo`. Dentro dela, a aba `Cadastro Corporativo` publica uma Lightning App Page com o componente LWC `cnpjSearch`, utilizado como interface principal da solução.

## 3. Arquitetura da Solução

### 3.1 Camada de Interface
O componente `cnpjSearch` foi desenvolvido em LWC para concentrar a experiência principal do usuário. Suas responsabilidades incluem:
- entrada do CNPJ
- validação básica do valor informado
- execução da busca dos dados
- exibição da origem dos dados consultados
- exibição da última atualização
- criação e atualização da empresa
- limpeza dos campos para nova consulta

### 3.2 Camada de Negócio
A classe `ReceitaWSService.cls` centraliza a lógica da aplicação. Suas responsabilidades incluem:
- validação do CNPJ
- consulta de conta existente por CNPJ
- chamada HTTP para a API ReceitaWS
- tratamento e mapeamento dos dados retornados
- construção das mensagens de origem e última atualização
- criação ou atualização do registro de `Account`
- prevenção de duplicidade por CNPJ

### 3.3 Camada de Automação
O requisito de automação foi atendido com a implementação de Screen Flow e ações invocáveis em Apex:
- `ReceitaWSFlowAction.cls`: responsável pela busca dos dados da empresa no Screen Flow
- `ReceitaWSSaveFlowAction.cls`: responsável pelo salvamento ou atualização da empresa no Screen Flow
- `Screen Flow Cadastro de Cliente Corporativo`: fluxo contendo entrada do CNPJ, chamada Apex de busca, revisão dos dados, chamada Apex de salvamento e tela de confirmação

## 4. Componentes Implementados

### 4.1 Apex
- `ReceitaWSService.cls`
- `ReceitaWSFlowAction.cls`
- `ReceitaWSSaveFlowAction.cls`

### 4.2 LWC
- `cnpjSearch`

### 4.3 Metadata e Configurações
- Campo personalizado `Account.CNPJ__c`
- Campo personalizado `Account.Status_Cadastral__c`
- Campo personalizado `Account.Ultima_Atualizacao_Receita__c`
- Lightning App `Cadastro de Cliente Corporativo`
- Lightning App Page `Cadastro Corporativo`
- Screen Flow `Cadastro de Cliente Corporativo`
- Permission Set `Representante de Vendas`

## 5. Fluxo Funcional

### 5.1 Consulta
1. O usuário acessa a app `Cadastro de Cliente Corporativo`.
2. Na aba `Cadastro Corporativo`, informa o CNPJ.
3. O sistema valida o valor informado.
4. O Apex verifica inicialmente se já existe `Account` com o mesmo CNPJ.
5. Quando existe registro, os dados são retornados do Salesforce.
6. Quando não existe registro, os dados são buscados na ReceitaWS.

### 5.2 Cadastro e Atualização
1. Os campos da empresa são preenchidos automaticamente.
2. O usuário pode revisar e editar as informações exibidas.
3. Quando a empresa não existe, o sistema permite o cadastro.
4. Quando a empresa já existe, o sistema permite a atualização.
5. O registro é persistido no objeto `Account`.
6. O campo `Ultima_Atualizacao_Receita__c` é atualizado no processo de salvamento.

## 6. Regras de Negócio
- O CNPJ é validado antes da consulta.
- O sistema consulta contas existentes para evitar duplicidade.
- A origem dos dados é identificada como `Salesforce` ou `ReceitaWS`.
- A data de última atualização é tratada no Apex.
- Quando a data não estiver disponível, o sistema utiliza mensagem de fallback amigável.
- No salvamento, caso a data não seja enviada, o Apex utiliza a data atual.

## 7. Mapeamento de Campos
- `ReceitaWS.nome` -> `Account.Name`
- `ReceitaWS.cnpj` -> `Account.CNPJ__c`
- `ReceitaWS.logradouro + número + complemento + bairro` -> `Account.BillingStreet`
- `ReceitaWS.município` -> `Account.BillingCity`
- `ReceitaWS.uf` -> `Account.BillingState`
- `ReceitaWS.cep` -> `Account.BillingPostalCode`
- `ReceitaWS.telefone` -> `Account.Phone`
- `ReceitaWS.situacao` -> `Account.Status_Cadastral__c`
- `data da integração` -> `Account.Ultima_Atualizacao_Receita__c`

## 8. Segurança e Acesso
Foi adotado o seguinte modelo de acesso:
- usuário com profile `Minimum Access - Salesforce`
- complementação de acesso por meio do Permission Set `Representante de Vendas`

Permissões concedidas:
- `Account`: Read, Create, Edit
- `Contact`: Read, Create, Edit
- acesso à app `Cadastro de Cliente Corporativo`
- acesso às classes Apex necessárias

Esse modelo reduz privilégios e atende ao requisito de restringir o processo a usuários autorizados.

## 9. Configuração da Org

### 9.1 Remote Site Setting
O endpoint configurado para permitir o callout externo é:
- `https://www.receitaws.com.br`

### 9.2 Campo Customizado
O campo abaixo deve existir no objeto `Account`:
- `Ultima_Atualizacao_Receita__c`
  - tipo `Date`

### 9.3 App e Página
A interface principal da solução foi publicada com os seguintes artefatos:
- Lightning App `Cadastro de Cliente Corporativo`
- Lightning App Page `Cadastro Corporativo`
- componente `cnpjSearch` como interface principal

### 9.4 Flow
O Screen Flow foi mantido ativo como parte da automação exigida pelo projeto.

## 10. Implantação
1. Realizar o deploy das classes Apex, do LWC e dos metadados.
2. Garantir a configuração do Remote Site Setting da ReceitaWS.
3. Publicar a app e a página Lightning.
4. Criar usuário com profile `Minimum Access - Salesforce`.
5. Atribuir o Permission Set `Representante de Vendas`.
6. Validar acesso à app, à página de cadastro e aos objetos necessários.

## 11. Considerações Técnicas
- A API pública da ReceitaWS possui limitação de uso gratuito. Recomenda-se evitar consultas em excesso em curto intervalo.
- A experiência principal foi mantida no LWC para melhorar usabilidade, responsividade e clareza das mensagens.
- O Screen Flow foi implementado para atender ao requisito de automação do projeto.

## 12. Evidências da Implementação
As evidências utilizadas para demonstrar a implementação contemplam:
- app principal `Cadastro de Cliente Corporativo`
- tela inicial do LWC `cnpjSearch`
- consulta de CNPJ não cadastrado
- consulta de CNPJ já existente na base Salesforce
- cadastro de empresa com sucesso
- atualização de empresa com sucesso
- registro de `Account` criado ou atualizado
- estrutura do Screen Flow no Flow Builder
- classes Apex de consulta e salvamento
- Permission Set `Representante de Vendas`
- usuário de teste com profile `Minimum Access - Salesforce`
- configuração de Remote Site Setting
