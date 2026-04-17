@IsTest
private class ReceitaWSServiceTest {

    private class ReceitaWSMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(
                '{' +
                '"nome":"CARREFOUR COMERCIO E INDUSTRIA LTDA",' +
                '"telefone":"(11) 9999-9999",' +
                '"logradouro":"AV TUCUNARE",' +
                '"numero":"125",' +
                '"complemento":"BLOCO C SALA 1 C101",' +
                '"bairro":"TAMBORE",' +
                '"municipio":"BARUERI",' +
                '"uf":"SP",' +
                '"cep":"06.460-020",' +
                '"situacao":"ATIVA"' +
                '}'
            );
            return res;
        }
    }

    @IsTest
    static void testConsultarCNPJContaExistente() {
        Account acc = new Account(
            Name = 'ATACADAO S.A.',
            CNPJ__c = '75.315.333/0001-09',
            Phone = '(11) 2967-8284',
            BillingStreet = 'AV MOVAN DIAS DE FIGUEIREDO, 6169',
            BillingCity = 'SAO PAULO',
            BillingState = 'SP',
            BillingPostalCode = '02111-000',
            BillingCountry = 'Brazil',
            Status_Cadastral__c = 'ATIVA',
            Ultima_Atualizacao_Receita__c = Date.newInstance(2026, 4, 16)
        );
        insert acc;

        Test.startTest();
        Map<String, Object> resultado = ReceitaWSService.consultarCNPJ('75.315.333/0001-09');
        Test.stopTest();

        System.assertEquals(true, resultado.get('registroExistente'));
        System.assertEquals(acc.Id, resultado.get('accountId'));
        System.assertEquals('Empresa encontrada na base do Salesforce.', resultado.get('mensagemOrigem'));
        System.assertNotEquals(null, resultado.get('mensagemUltimaAtualizacao'));
    }

    @IsTest
    static void testConsultarCNPJViaReceitaWS() {
        Test.setMock(HttpCalloutMock.class, new ReceitaWSMock());

        Test.startTest();
        Map<String, Object> resultado = ReceitaWSService.consultarCNPJ('45.543.915/0001-81');
        Test.stopTest();

        System.assertEquals(false, resultado.get('registroExistente'));
        System.assertEquals('CARREFOUR COMERCIO E INDUSTRIA LTDA', resultado.get('nome'));
        System.assertEquals('ATIVA', resultado.get('situacao'));
        System.assertEquals('Dados obtidos na ReceitaWS.', resultado.get('mensagemOrigem'));
        System.assertNotEquals(null, resultado.get('mensagemUltimaAtualizacao'));
    }

    @IsTest
    static void testSalvarAccountCriandoNovoRegistro() {
        Map<String, Object> dados = new Map<String, Object>{
            'nome' => 'EMPRESA TESTE LTDA',
            'cnpj' => '45.543.915/0001-81',
            'telefone' => '(11) 9999-9999',
            'logradouro' => 'RUA TESTE, 100',
            'municipio' => 'SAO PAULO',
            'uf' => 'SP',
            'cep' => '01000-000',
            'pais' => 'Brazil',
            'situacao' => 'ATIVA',
            'ultimaAtualizacao' => '2026-04-16'
        };

        Test.startTest();
        String accountId = ReceitaWSService.salvarAccount(dados);
        Test.stopTest();

        Account acc = [
            SELECT Id, Name, CNPJ__c, Phone, BillingStreet, BillingCity, BillingState,
                   BillingPostalCode, BillingCountry, Status_Cadastral__c, Ultima_Atualizacao_Receita__c
            FROM Account
            WHERE Id = :accountId
        ];

        System.assertEquals('EMPRESA TESTE LTDA', acc.Name);
        System.assertEquals('45.543.915/0001-81', acc.CNPJ__c);
        System.assertEquals('ATIVA', acc.Status_Cadastral__c);
        System.assertEquals(Date.newInstance(2026, 4, 16), acc.Ultima_Atualizacao_Receita__c);
    }

    @IsTest
    static void testSalvarAccountAtualizandoExistente() {
        Account acc = new Account(
            Name = 'EMPRESA ANTIGA',
            CNPJ__c = '75.315.333/0001-09',
            Phone = '(11) 1111-1111'
        );
        insert acc;

        Map<String, Object> dados = new Map<String, Object>{
            'accountId' => acc.Id,
            'nome' => 'EMPRESA ATUALIZADA',
            'cnpj' => '75.315.333/0001-09',
            'telefone' => '(11) 2222-2222',
            'logradouro' => 'RUA NOVA, 200',
            'municipio' => 'GUARULHOS',
            'uf' => 'SP',
            'cep' => '07000-000',
            'pais' => 'Brazil',
            'situacao' => 'ATIVA',
            'ultimaAtualizacao' => null
        };

        Test.startTest();
        String accountId = ReceitaWSService.salvarAccount(dados);
        Test.stopTest();

        Account atualizado = [
            SELECT Id, Name, Phone, BillingStreet, BillingCity, BillingState,
                   BillingPostalCode, BillingCountry, Status_Cadastral__c, Ultima_Atualizacao_Receita__c
            FROM Account
            WHERE Id = :accountId
        ];

        System.assertEquals(acc.Id, atualizado.Id);
        System.assertEquals('EMPRESA ATUALIZADA', atualizado.Name);
        System.assertEquals('(11) 2222-2222', atualizado.Phone);
        System.assertEquals(Date.today(), atualizado.Ultima_Atualizacao_Receita__c);
    }

    @IsTest
    static void testReceitaWSFlowAction() {
        Test.setMock(HttpCalloutMock.class, new ReceitaWSMock());

        ReceitaWSFlowAction.FlowInput input = new ReceitaWSFlowAction.FlowInput();
        input.cnpj = '45.543.915/0001-81';

        Test.startTest();
        List<ReceitaWSFlowAction.FlowOutput> outputs =
            ReceitaWSFlowAction.buscarEmpresa(new List<ReceitaWSFlowAction.FlowInput>{ input });
        Test.stopTest();

        System.assertEquals(1, outputs.size());
        System.assertEquals('CARREFOUR COMERCIO E INDUSTRIA LTDA', outputs[0].nome);
        System.assertEquals('Dados obtidos na ReceitaWS.', outputs[0].mensagemOrigem);
    }

    @IsTest
    static void testReceitaWSSaveFlowAction() {
        ReceitaWSSaveFlowAction.FlowInput input = new ReceitaWSSaveFlowAction.FlowInput();
        input.nome = 'EMPRESA FLOW LTDA';
        input.cnpj = '45.543.915/0001-81';
        input.telefone = '(11) 9999-9999';
        input.logradouro = 'RUA FLOW, 123';
        input.municipio = 'OSASCO';
        input.uf = 'SP';
        input.cep = '06000-000';
        input.pais = 'Brazil';
        input.situacao = 'ATIVA';
        input.ultimaAtualizacao = '2026-04-16';

        Test.startTest();
        List<ReceitaWSSaveFlowAction.FlowOutput> outputs =
            ReceitaWSSaveFlowAction.salvarEmpresa(new List<ReceitaWSSaveFlowAction.FlowInput>{ input });
        Test.stopTest();

        System.assertEquals(1, outputs.size());
        System.assertNotEquals(null, outputs[0].accountId);
        System.assertEquals('Empresa cadastrada com sucesso.', outputs[0].mensagem);
    }
}
