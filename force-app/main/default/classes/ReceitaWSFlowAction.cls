/**
 * Exposicao da consulta de CNPJ para uso em Screen Flows.
 */
public with sharing class ReceitaWSFlowAction {
    public class FlowInput {
        @InvocableVariable(required=true)
        public String cnpj;
    }

    public class FlowOutput {
        @InvocableVariable public Boolean registroExistente;
        @InvocableVariable public String accountId;
        @InvocableVariable public String nome;
        @InvocableVariable public String cnpj;
        @InvocableVariable public String telefone;
        @InvocableVariable public String logradouro;
        @InvocableVariable public String municipio;
        @InvocableVariable public String uf;
        @InvocableVariable public String cep;
        @InvocableVariable public String pais;
        @InvocableVariable public String situacao;
        @InvocableVariable public String ultimaAtualizacao;
        @InvocableVariable public String mensagemOrigem;
        @InvocableVariable public String mensagemUltimaAtualizacao;
    }

    @InvocableMethod(label='Buscar empresa por CNPJ na ReceitaWS' description='Consulta Account existente e, se necessario, busca dados na ReceitaWS.')
    public static List<FlowOutput> buscarEmpresa(List<FlowInput> inputs) {
        List<FlowOutput> outputs = new List<FlowOutput>();

        for (FlowInput item : inputs) {
            // Reaproveita a mesma regra de negocio usada pelo LWC para manter o comportamento consistente.
            Map<String, Object> resultado = ReceitaWSService.consultarCNPJ(item.cnpj);
            FlowOutput output = new FlowOutput();

            if (resultado != null) {
                // Expõe para o Flow apenas os campos necessarios para revisao, exibicao e salvamento.
                output.registroExistente = (Boolean) resultado.get('registroExistente');
                output.accountId = resultado.get('accountId') == null ? null : String.valueOf(resultado.get('accountId'));
                output.nome = (String) resultado.get('nome');
                output.cnpj = (String) resultado.get('cnpj');
                output.telefone = (String) resultado.get('telefone');
                output.logradouro = (String) resultado.get('logradouro');
                output.municipio = (String) resultado.get('municipio');
                output.uf = (String) resultado.get('uf');
                output.cep = (String) resultado.get('cep');
                output.pais = (String) resultado.get('pais');
                output.situacao = (String) resultado.get('situacao');
                output.ultimaAtualizacao = resultado.get('ultimaAtualizacao') == null ? null : String.valueOf(resultado.get('ultimaAtualizacao'));
                output.mensagemOrigem = (String) resultado.get('mensagemOrigem');
                output.mensagemUltimaAtualizacao = (String) resultado.get('mensagemUltimaAtualizacao');
            }

            outputs.add(output);
        }

        return outputs;
    }
}
