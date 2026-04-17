/**
 * Exposicao do salvamento do cadastro corporativo para uso em Screen Flows.
 */
public with sharing class ReceitaWSSaveFlowAction {
    public class FlowInput {
        @InvocableVariable public String accountId;
        @InvocableVariable(required=true) public String nome;
        @InvocableVariable(required=true) public String cnpj;
        @InvocableVariable public String telefone;
        @InvocableVariable public String logradouro;
        @InvocableVariable public String municipio;
        @InvocableVariable public String uf;
        @InvocableVariable public String cep;
        @InvocableVariable public String pais;
        @InvocableVariable public String situacao;
        @InvocableVariable public String ultimaAtualizacao;
    }

    public class FlowOutput {
        @InvocableVariable public String accountId;
        @InvocableVariable public String mensagem;
    }

    @InvocableMethod(label='Salvar empresa do cadastro corporativo' description='Cria ou atualiza uma Account a partir dos dados revisados no Screen Flow.')
    public static List<FlowOutput> salvarEmpresa(List<FlowInput> inputs) {
        List<FlowOutput> outputs = new List<FlowOutput>();

        for (FlowInput item : inputs) {
            // O Flow envia os dados revisados e a regra de persistencia permanece centralizada no service.
            Map<String, Object> dados = new Map<String, Object>{
                'accountId' => item.accountId,
                'nome' => item.nome,
                'cnpj' => item.cnpj,
                'telefone' => item.telefone,
                'logradouro' => item.logradouro,
                'municipio' => item.municipio,
                'uf' => item.uf,
                'cep' => item.cep,
                'pais' => String.isBlank(item.pais) ? 'Brazil' : item.pais,
                'situacao' => item.situacao,
                'ultimaAtualizacao' => item.ultimaAtualizacao
            };

            String accountId = ReceitaWSService.salvarAccount(dados);

            FlowOutput output = new FlowOutput();
            output.accountId = accountId;
            // A mensagem final muda conforme o processo tenha criado ou atualizado a empresa.
            output.mensagem = String.isBlank(item.accountId)
                ? 'Empresa cadastrada com sucesso.'
                : 'Empresa atualizada com sucesso.';
            outputs.add(output);
        }

        return outputs;
    }
}
