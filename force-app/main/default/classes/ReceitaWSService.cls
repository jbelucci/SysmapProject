/**
 * Centraliza a integracao com a ReceitaWS e a persistencia do cadastro corporativo.
 */
public with sharing class ReceitaWSService {

    private static final String ENDPOINT = 'https://www.receitaws.com.br/v1/cnpj/';

    /**
     * Remove qualquer caractere que nao seja numero do CNPJ informado.
     */
    private static String limparCNPJ(String cnpj) {
        return String.isBlank(cnpj) ? '' : cnpj.replaceAll('[^0-9]', '');
    }

    /**
     * Evita concatenacoes com valores nulos.
     */
    private static String textoOuVazio(Object valor) {
        return valor == null ? '' : String.valueOf(valor).trim();
    }

    /**
     * Monta o endereco em um bloco legivel, usando quebra de linha quando houver complemento.
     */
    private static String montarLogradouro(Object logradouro, Object numero, Object complemento, Object bairro) {
        String primeiraLinha = textoOuVazio(logradouro);
        String numeroTexto = textoOuVazio(numero);
        String complementoTexto = textoOuVazio(complemento);
        String bairroTexto = textoOuVazio(bairro);

        if (!String.isBlank(numeroTexto)) {
            primeiraLinha = String.isBlank(primeiraLinha)
                ? numeroTexto
                : primeiraLinha + ', ' + numeroTexto;
        }

        String segundaLinha = complementoTexto;
        if (!String.isBlank(bairroTexto)) {
            segundaLinha = String.isBlank(segundaLinha)
                ? bairroTexto
                : segundaLinha + ' - ' + bairroTexto;
        }

        if (String.isBlank(primeiraLinha)) {
            return segundaLinha;
        }

        if (String.isBlank(segundaLinha)) {
            return primeiraLinha;
        }

        return primeiraLinha + '\n' + segundaLinha;
    }

    /**
     * Formata a mensagem de ultima atualizacao de forma consistente para o Flow e para o LWC.
     */
    private static String montarMensagemUltimaAtualizacao(Date dataAtualizacao) {
        return dataAtualizacao == null
            ? 'Ultima atualizacao nao disponivel.'
            : 'Ultima atualizacao: ' + dataAtualizacao.format();
    }

    /**
     * Valida os digitos verificadores do CNPJ.
     */
    private static Boolean validarCNPJ(String cnpj) {
        if (String.isBlank(cnpj) || cnpj.length() != 14 || cnpj.replaceAll(cnpj.substring(0,1), '').length() == 0) {
            return false;
        }

        Integer soma = 0;
        Integer peso = 5;
        for (Integer i = 0; i < 12; i++) {
            soma += Integer.valueOf(cnpj.substring(i, i+1)) * peso;
            peso = peso == 2 ? 9 : peso - 1;
        }
        Integer primeiro = Math.mod(soma, 11) < 2 ? 0 : 11 - Math.mod(soma, 11);

        soma = 0;
        peso = 6;
        for (Integer i = 0; i < 13; i++) {
            soma += Integer.valueOf(cnpj.substring(i, i+1)) * peso;
            peso = peso == 2 ? 9 : peso - 1;
        }
        Integer segundo = Math.mod(soma, 11) < 2 ? 0 : 11 - Math.mod(soma, 11);

        return primeiro == Integer.valueOf(cnpj.substring(12, 13)) &&
               segundo == Integer.valueOf(cnpj.substring(13, 14));
    }

    /**
     * Localiza uma conta existente pelo CNPJ limpo ou formatado para evitar duplicidade.
     */
    private static Account buscarContaExistente(String cnpjOriginal, String cnpjLimpo) {
        List<Account> contasExistentes = [
            SELECT Id, Name, CNPJ__c, Phone, BillingStreet,
                   BillingCity, BillingState, BillingPostalCode,
                   BillingCountry, Status_Cadastral__c, Ultima_Atualizacao_Receita__c
            FROM Account
            WHERE CNPJ__c IN :new Set<String>{ cnpjOriginal, cnpjLimpo }
            LIMIT 1
        ];

        return contasExistentes.isEmpty() ? null : contasExistentes[0];
    }

    @AuraEnabled
    public static Map<String, Object> consultarCNPJ(String cnpj) {
        try {
            String cnpjLimpo = limparCNPJ(cnpj);

            if (cnpjLimpo.length() != 14) {
                throw new AuraHandledException('CNPJ invalido. O CNPJ deve conter 14 digitos.');
            }

            if (!validarCNPJ(cnpjLimpo)) {
                throw new AuraHandledException('CNPJ invalido. Verifique os digitos informados.');
            }

            // Prioriza a base Salesforce para evitar chamadas externas desnecessarias e duplicidade.
            Account contaExistente = buscarContaExistente(cnpj, cnpjLimpo);
            if (contaExistente != null) {
                Map<String, Object> dadosExistentes = new Map<String, Object>();
                dadosExistentes.put('registroExistente', true);
                dadosExistentes.put('accountId', contaExistente.Id);
                dadosExistentes.put('nome', contaExistente.Name);
                dadosExistentes.put('cnpj', contaExistente.CNPJ__c);
                dadosExistentes.put('telefone', contaExistente.Phone);
                dadosExistentes.put('logradouro', contaExistente.BillingStreet);
                dadosExistentes.put('municipio', contaExistente.BillingCity);
                dadosExistentes.put('uf', contaExistente.BillingState);
                dadosExistentes.put('cep', contaExistente.BillingPostalCode);
                dadosExistentes.put('pais', contaExistente.BillingCountry);
                dadosExistentes.put('situacao', contaExistente.Status_Cadastral__c);
                dadosExistentes.put(
                    'ultimaAtualizacao',
                    contaExistente.Ultima_Atualizacao_Receita__c == null
                        ? null
                        : String.valueOf(contaExistente.Ultima_Atualizacao_Receita__c)
                );
                dadosExistentes.put('mensagemOrigem', 'Empresa encontrada na base do Salesforce.');
                dadosExistentes.put(
                    'mensagemUltimaAtualizacao',
                    montarMensagemUltimaAtualizacao(contaExistente.Ultima_Atualizacao_Receita__c)
                );
                return dadosExistentes;
            }

            HttpRequest req = new HttpRequest();
            req.setEndpoint(ENDPOINT + cnpjLimpo);
            req.setMethod('GET');
            req.setTimeout(120000);

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() != 200) {
                throw new AuraHandledException('Erro ao consultar CNPJ. Tente novamente mais tarde.');
            }

            Map<String, Object> dados = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

            if (dados.get('status') == 'ERROR') {
                throw new AuraHandledException('CNPJ nao encontrado na Receita Federal.');
            }

            // Consolida o endereco em um unico bloco para facilitar exibicao no LWC e persistencia no Account.
            String logradouro = montarLogradouro(
                dados.get('logradouro'),
                dados.get('numero'),
                dados.get('complemento'),
                dados.get('bairro')
            );

            Map<String, Object> retorno = new Map<String, Object>();
            retorno.put('registroExistente', false);
            retorno.put('accountId', null);
            retorno.put('nome', dados.get('nome'));
            retorno.put('cnpj', cnpj);
            retorno.put('telefone', dados.get('telefone'));
            retorno.put('logradouro', logradouro);
            retorno.put('municipio', dados.get('municipio'));
            retorno.put('uf', dados.get('uf'));
            retorno.put('cep', dados.get('cep'));
            retorno.put('pais', 'Brazil');
            retorno.put('situacao', dados.get('situacao'));
            retorno.put('numero', dados.get('numero'));
            retorno.put('complemento', dados.get('complemento'));
            retorno.put('bairro', dados.get('bairro'));
            retorno.put('ultimaAtualizacao', String.valueOf(Date.today()));
            retorno.put('mensagemOrigem', 'Dados obtidos na ReceitaWS.');
            retorno.put('mensagemUltimaAtualizacao', montarMensagemUltimaAtualizacao(Date.today()));

            return retorno;

        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Erro inesperado: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String salvarAccount(Map<String, Object> dados) {
        try {
            Account acc = new Account();
            String cnpjInformado = (String) dados.get('cnpj');
            String cnpjLimpo = limparCNPJ(cnpjInformado);

            // Atualiza a conta informada ou reaproveita um registro existente com o mesmo CNPJ.
            if (dados.get('accountId') != null) {
                acc.Id = (Id) dados.get('accountId');
            } else {
                Account existente = buscarContaExistente(cnpjInformado, cnpjLimpo);
                if (existente != null) {
                    acc.Id = existente.Id;
                }
            }

            acc.Name = (String) dados.get('nome');
            acc.CNPJ__c = cnpjInformado;
            acc.Phone = (String) dados.get('telefone');
            acc.BillingStreet = (String) dados.get('logradouro');
            acc.BillingCity = (String) dados.get('municipio');
            acc.BillingState = (String) dados.get('uf');
            acc.BillingPostalCode = (String) dados.get('cep');
            acc.BillingCountry = (String) dados.get('pais');
            acc.Status_Cadastral__c = (String) dados.get('situacao');

            if (Schema.sObjectType.Account.fields.getMap().containsKey('Ultima_Atualizacao_Receita__c')) {
                Object ultimaAtualizacao = dados.get('ultimaAtualizacao');
                // Quando a data nao e enviada pela camada de interface, utiliza a data corrente da integracao.
                acc.put(
                    'Ultima_Atualizacao_Receita__c',
                    ultimaAtualizacao == null || String.isBlank(String.valueOf(ultimaAtualizacao))
                        ? Date.today()
                        : Date.valueOf(String.valueOf(ultimaAtualizacao))
                );
            }

            upsert acc;

            return acc.Id;

        } catch (Exception e) {
            throw new AuraHandledException('Erro ao salvar empresa: ' + e.getMessage());
        }
    }
}
