import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import consultarCNPJ from '@salesforce/apex/ReceitaWSService.consultarCNPJ';
import salvarAccount from '@salesforce/apex/ReceitaWSService.salvarAccount';

export default class CnpjSearch extends NavigationMixin(LightningElement) {
    
    // Variaveis de controle
    @track cnpj = '';
    @track dadosEmpresa = {};
    @track isLoading = false;
    @track mostrarFormulario = false;
    @track registroExistente = false;
    @track contadorCadastros = 0;

    // Label dinamico do botao salvar
    get labelBotaoSalvar() {
        return this.registroExistente ? 'Atualizar Empresa' : 'Cadastrar Empresa';
    }

    get labelBotaoSalvarENovo() {
        return this.registroExistente ? 'Atualizar e Buscar Nova Empresa' : 'Cadastrar Empresa e Buscar Nova';
    }

    get mensagemOrigem() {
        return this.dadosEmpresa?.mensagemOrigem;
    }

    get mensagemUltimaAtualizacao() {
        return this.dadosEmpresa?.mensagemUltimaAtualizacao;
    }

    get exibirMensagemOrigem() {
        return this.mostrarFormulario && !!this.mensagemOrigem;
    }

    get exibirMensagemUltimaAtualizacao() {
        return this.mostrarFormulario && !!this.mensagemUltimaAtualizacao;
    }

    // Formata o CNPJ automaticamente enquanto digita
    handleCnpjChange(event) {
        let valor = event.target.value.replace(/[^0-9]/g, '');
        if (valor.length <= 14) {
            valor = valor
                .replace(/^(\d{2})(\d)/, '$1.$2')
                .replace(/^(\d{2})\.(\d{3})(\d)/, '$1.$2.$3')
                .replace(/\.(\d{3})(\d)/, '.$1/$2')
                .replace(/(\d{4})(\d)/, '$1-$2');
            this.cnpj = valor;
        }
    }

    // Atualiza os campos do formulario quando editados
    handleFieldChange(event) {
        const field = event.target.dataset.field;
        this.dadosEmpresa = { ...this.dadosEmpresa, [field]: event.target.value };
    }

    // Busca o CNPJ
    async handleBuscar() {
        if (!this.cnpj || this.cnpj.length < 18) {
            this.showToast('Atencao', 'Digite um CNPJ valido no formato XX.XXX.XXX/XXXX-XX', 'warning');
            return;
        }

        this.isLoading = true;
        this.mostrarFormulario = false;

        try {
            const resultado = await consultarCNPJ({ cnpj: this.cnpj });
            this.dadosEmpresa = resultado;
            this.registroExistente = resultado.registroExistente;
            this.mostrarFormulario = true;
        } catch (error) {
            this.showToast('Erro', error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Salva e permanece na tela
    async handleSalvar() {
        this.isLoading = true;
        try {
            const accountId = await salvarAccount({ dados: this.dadosEmpresa });
            this.contadorCadastros++;
            const mensagem = this.registroExistente ? 'Cadastro atualizado com sucesso!' : 'Empresa cadastrada com sucesso!';
            this.showToast('Sucesso', mensagem, 'success');
            
            // Redireciona para o registro criado/atualizado
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: accountId,
                    actionName: 'view'
                }
            });
        } catch (error) {
            this.showToast('Erro', error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Salva e limpa o formulario para nova busca
    async handleSalvarENovo() {
        this.isLoading = true;
        try {
            await salvarAccount({ dados: this.dadosEmpresa });
            this.contadorCadastros++;
            const mensagem = this.registroExistente ? 'Cadastro atualizado!' : 'Empresa cadastrada!';
            this.showToast('Sucesso', mensagem, 'success');
            this.handleLimpar();
        } catch (error) {
            this.showToast('Erro', error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Limpa o formulario
    handleLimpar() {
        this.cnpj = '';
        this.dadosEmpresa = {};
        this.mostrarFormulario = false;
        this.registroExistente = false;
    }

    // Exibe toast de notificacao
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
