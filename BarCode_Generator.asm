;TRABALHO INTEL
.model small
.stack

.data
;Strings
CR EQU  0Dh ;carriage return
LF EQU  0Ah ;line feed, move o cursor uma linha para baixo
CR_LF DB 13, 10, 0
strA DB 'START',0 
strB DB 'STOP',0
strC DB '|Caractere Invalido!|', 0
strD DB '|Erro: numero maximo de digitos permitidos por linha foi excedido!|', 0

;Variáveis no geral
BUFFER DB 1 ;Buffer para guardar o byte lido no arquivo
Vet_Seq_Num DB 10 dup(0) ;dw ou db, dá o mesmo erro
pos_vet DW 0 
Zero DB '0',0 
Dez DB '10', '$',0
Count_Num DB 0 ;contador para o número de caracteres na linha, se exceder 10, dá mensagem de erro, falando q excedeu
; e vai pra próxima linha
Count_Linha DB 1 ; contador para determinar em qual erro foi a linha e quando excede 50 linhas
Bar_Code_Especial DB 0
;dois_cr_lf DB 0 ;usado para caso o arquivo contenha apenas uma linha em branco entre o START e o STOP

;Variáveis para calcular o Dígito Verificador
Dig_Verificador DW 0, '$';Variável que será o dígito verificador ;CUIDADO PARA NÃO DAR OVERFLOW
Peso_Dig_Verificador DB 1

;handles dos arquivos de texto e de barras
handle_arq_txt DW ? ;handle do arquivo de texto
handle_arq_bar DW ? ;handle do arquivo de barras

;arquivos de texto e de barras
nome_arq_txt DB 'IN.TXT', 0
nome_arq_bar DB 'OUT.BAR', 0

;mensagens no geral
;mensagens sobre o arquivo
mensagem_erro_abrir DB 'Erro ao abrir o arquivo de texto!', CR, LF,'$',0
mensagem_erro_criar DB 'Erro ao criar o arquivo de barras!', CR, LF,'$',0
mensagem_erro_fechar_txt DB 'Erro ao fechar arquivo de texto!', CR, LF, '$', 0
mensagem_erro_fechar_bar DB 'Erro ao fechar arquivo de barras!', CR, LF, '$', 0
mensagem_arquivo_aberto DB 'Sucesso ao abrir o arquivo de barras!', CR, LF,'$',0 
mensagem_arquivo_fechado DB 'Arquivo fechado com sucesso!', CR, LF, '$',0
mensagem_arquivo_criado DB 'Arquivo de barras criado com sucesso', CR, LF, '$',0

;mensagens sobre escrita
mensagem_start DB 'START ENCONTRADO!', CR, LF,'$',0
mensagem_start_NF DB 'START NAO FOI ENCONTRADO!', CR, LF,'$',0
mensagem_start_escrito DB 'START escrito no arquivo de barras!', CR, LF, '$', 0
mensagem_digito_calculado DB 'Digito verificador calculado!', CR, LF, '$', 0
mensagem_erro_zero DB 'Erro ao escrever zero no arquivo de barras!', CR, LF, '$',0
mensagem_erro_escrever_bar DB 'Erro ao escrever no arquivo de barras!', CR, LF, '$', 0
mensagem_caractere_invalido DB 'Caractere invalido encontrado na linha:', CR, LF, '$', 0
mensagem_max_num_linha DB 'O numero maximo de caracteres foi excedido na linha:', CR, LF, '$', 0


;flags usadas ao longo do programa
flag_arq_criado DB 0; flag usada para determinar se o arquivo .bar foi criado com sucesso
flag_cr DB 0 ;flag usada para determinar se teve CR no arquivo de texto
flag_ss DB 0;flag usada para printar os ss no arquivo .BAR
flag_fim_linha DB 0
flag_ignora DB 0

;BarCodes
SS_codigo DB '1011001', 0
BAR_CODES DB '101011', 0,'1101011', '1001011', '1100101', '1011011', '1101101', '1001101', '1010011', '1101001', '110101', 0,'101101', 0, 0
.code
	.startup
;=========================================================================================================================
	
	;começamos abrindo o arquivo de texto
	MOV AH, 3DH
	MOV AL, 0 ;modo read only
	LEA DX, nome_arq_txt
	INT 21H
	JC ERRO_ABRIR_ARQUIVO
	MOV BX, AX ; movemos o handle do arquivo de AX para BX
	
;=========================================================================================================================
	MOV DX, DS
	MOV ES, DX
	MOV SI, 0
	MOV DI, 0 ;será usado no programa gerador posteriormente, no vetor que guarda os números por linha
Funcao_Le_Arquivo_TXT:
	MOV AH, 3FH
	LEA DX, BUFFER
	MOV CX, 1
	INT 21H
	
	CMP AX, 0 
	JE Fim_Programa
	
	CMP flag_ignora, 1
	JE Loop_Ignora_ate_CR
	
	CMP flag_arq_criado, 1
	JE Programa_Gerador
	
	;comparamos o byte lido no arquivo com a palavra "START"
	CALL Funcao_Compara_Palavras
	CMP AL, 1
	JE START_ENCONTRADO
	
	JMP Funcao_Le_Arquivo_TXT

;=========================================================================================================================
;Função usada para ver onde está a palavra START no arquivo TXT

Funcao_Compara_Palavras: 
	MOV AL, [BUFFER]
	CMP AL, [SI+strA]
	JNE Restart_Loop_Comparacao
	INC SI
	CMP SI, 5
	JE Palavra_Encontrada
	JMP Retorno

Restart_Loop_Comparacao:
	MOV SI, 0
	JMP Retorno

Palavra_Encontrada:
	MOV AL, 1
	RET

Retorno:
	MOV AL, 0
	RET

;=========================================================================================================================
;Mensagens para o usuário
	
START_ENCONTRADO:
	MOV AH, 09H
	LEA DX, mensagem_start
	INT 21H
	JMP Cria_Arquivo_bar

;função caso start NÃO for ENCONTRADO
START_NAO_ENCONTRADO:
	MOV AH, 09H
	LEA DX, mensagem_start_NF
	INT 21H
	CALL Funcao_Fecha_Arquivo
	JC ERRO_FECHAR_ARQUIVO_TXT
	JMP Fim_Programa

ERRO_ABRIR_ARQUIVO:
	MOV AH, 09H
	LEA DX, mensagem_erro_abrir
	INT 21H
	JMP Fim_Programa

ERRO_CRIAR_ARQUIVO:
	MOV AH, 09H
	LEA DX, mensagem_erro_criar
	INT 21H
	JMP Fim_Programa
	
ERRO_ESCREVE_ZERO:
	MOV AH, 09H
	LEA DX, mensagem_erro_zero
	INT 21H
	JMP Fim_Programa

ERRO_FECHAR_ARQUIVO_TXT:
	MOV AH, 09H
	LEA DX, mensagem_erro_fechar_txt
	INT 21H
	JMP Fim_Programa
	
ERRO_FECHAR_ARQUIVO_BAR:
	MOV AH, 09H
	LEA DX, mensagem_erro_fechar_bar 
	INT 21H
	JMP Fim_Programa
	
ERRO_ESCRITA:
	MOV AH, 09H
	LEA DX, mensagem_erro_escrever_bar 
	INT 21H
	JMP Fim_Programa
	

Mensagem_Calculo_Dig_Verif:	
	MOV AH, 09H
    LEA DX, mensagem_digito_calculado
    INT 21H
	RET
	
Mensagem_Encontra_Caractere_Invalido:
	MOV AH, 09H
	LEA DX, mensagem_caractere_invalido
	INT 21H
	
	MOV AL, Count_Linha
    ADD AL, '0'; Converte para ASCII ('0' = 30h)
	MOV Count_Linha, AL
	
	MOV AH, 09H
	LEA DX, Count_Linha
	INT 21H
	
	SUB Count_Linha, '0'
	RET

Mensagem_MAX_LINHA_Excedido:
	MOV AH, 09H
	LEA DX, mensagem_max_num_linha
	INT 21H
	
	MOV AL, Count_Linha
    ADD AL, '0'; Converte para ASCII ('0' = 30h)
	MOV Count_Linha, AL
	
	MOV AH, 09H
	LEA DX, Count_Linha
	INT 21H
	
	SUB Count_Linha, '0'
	RET
	
;===========================================================================================================================
;Funções sobre arquivo .BAR

Cria_Arquivo_bar:
	MOV handle_arq_txt, BX ;guardamos o handle do arquivo de texto em uma variável
	MOV AH, 3CH
	MOV CX, 0
	LEA DX, nome_arq_bar
	INT 21H
	JC ERRO_CRIAR_ARQUIVO
	MOV handle_arq_bar, AX ;vamos mover o handle do arquivo de barras de AX para BX   
	MOV BX, handle_arq_bar
	
	MOV flag_arq_criado, 1
	
	MOV AH, 09H
	LEA DX, mensagem_arquivo_criado ;vamos informar ao usuário que o arquivo .bar foi criado com sucesso
	INT 21H

Escrever_Arquivo_bar_start:	;começamos escrevendo START no arquivo .BAR
	MOV AH, 40H
	MOV BX, handle_arq_bar
	LEA DX, strA
	MOV CX, 5
	INT 21H
	JC ERRO_ESCRITA
	
	CALL Quebra_de_Linha
	
	MOV AH, 09H
	LEA DX, mensagem_start_escrito ;vamos informar ao usuário que o arquivo .bar foi criado com sucesso
	INT 21H
	
	MOV handle_arq_bar, BX
	MOV BX, handle_arq_txt
	MOV SI, 0
	JMP Funcao_Le_Arquivo_TXT

;=================================================================================================================

Funcao_Fecha_Arquivo:
	MOV AH, 3EH
	INT 21H
	
	MOV AH, 09H
	LEA DX, mensagem_arquivo_fechado
	INT 21H
	RET

Fim_Programa:; Termina o programa
    MOV AH, 4Ch
    INT 21h

;=========================================================================================================================

Programa_Gerador:
	CMP flag_cr, 1
	JE pula_lf
	CMP flag_fim_linha, 1
	JE Funcao_Compara_STOP
	
Funcao_Compara_CR: 
	MOV AL, [BUFFER]
	CMP AL, CR;sempre checamos se o simbolo é CR, para ver se a sequência de números acabou ou não
	JNE Le_Sequencia_Num ; se não for igual, vamos checar a sequência de números que formam a barra
	MOV flag_cr, 1 ;sempre que for para uma nova linha, vai ler CR primeiro
	JMP Funcao_Le_Arquivo_TXT ; depois do CR, vai ler LF

pula_lf: ; não precisamos ler CR, então só lemos o próximo byte, que será um número
	MOV flag_cr, 0
	
	;aqui pra checar se ultrapassou o número de caracteres da linha
	
SS_Encontrado:
	CMP flag_ss, 1
	JE Calcula_Dig_Verificador ;se chegamos houve quebra de linha, calculamos o dígito Verificador
	MOV handle_arq_txt, BX
	MOV BX, handle_arq_bar
	
Printa_SS:
	MOV AH, 40H
	LEA DX, SS_codigo ;printamos o código ss no arquivo de barras
	MOV CX, 7
	INT 21H
	
	ADD flag_ss, 1
	CMP  BYTE PTR [flag_ss], 2
	JE Proxima_Linha ;se o ss for igual a 2, significa que chegamos ao final da linha, então vamos para a próxima
	
	MOV AH, 40H
	LEA DX, Zero ;escrevemos zero após o primeiro SS
	MOV CX, 1
	INT 21H
	JC ERRO_ESCREVE_ZERO
	
	MOV handle_arq_bar, BX 
	MOV BX, handle_arq_txt
	JMP Funcao_Le_Arquivo_TXT
	
;==================================================================================================================

Le_Sequencia_Num:
	MOV handle_arq_txt, BX
	MOV BX, handle_arq_bar
Le_Sequencia_Num_2:
	LEA SI, BAR_CODES ; movemos o conteúdo do vetor BAR_CODES para SI
	CALL Subrotina
	CMP AL, 0
	JE Caractere_Invalido_Mostra_Mensagem
	INC BYTE PTR [Count_Num]
	CMP [Count_Num], 11
	JE Max_Linha ; se o número de caracteres da linha exceder 10, vamos ter que ir para a próxima
	CMP [Bar_Code_Especial], 1
	JE Chama_Printa_Especial
	CALL Printa_Barcode
	JMP Printa_zero
	
Subrotina:
	MOV DL, [BUFFER]
	CMP DL, 2DH
	JE Modifica_Hifen
	SUB DL, 30H
	CALL Verifica_Caractere_Valido
	CMP AL, 0
	JE Retorno_Subrotina
	PUSH BX
	LEA DI, Vet_Seq_Num;colocamos a sequência de número em um vetor, para calcular o dígito verificador depois	
	MOV BX, [pos_vet]
	MOV [DI+BX], DL ; transformamos o número em ASCII para número de fato e o colocamos no vetor
	INC BYTE PTR [pos_vet]
	POP BX
	CMP DL, 0
	JE BarCode_Esp_Encontrado
	CMP DL, 9
	JE BarCode_Esp_Encontrado
	
Loop_nsei:
	CMP DL, 0
	JE Retorno_Subrotina
	ADD SI, 7
	DEC DL
	JMP Loop_nsei

Modifica_Hifen:
	SUB DL, 35
	CALL Verifica_Caractere_Valido
	CMP AL, 0
	JE Retorno_Subrotina
	PUSH BX
	LEA DI, Vet_Seq_Num;colocamos a sequência de número em um vetor, para calcular o dígito verificador depois	
	MOV BX, [pos_vet]
	MOV [DI+BX], DL ; transformamos o número em ASCII para número de fato e o colocamos no vetor
	INC BYTE PTR [pos_vet]
	POP BX
	JMP BarCode_Esp_Encontrado
	
Retorno_Subrotina:
	RET
	
BarCode_Esp_Encontrado:
	MOV [Bar_Code_Especial], 1
	JMP Loop_nsei
	
Chama_Printa_Especial:
	CALL Printa_Barcode_Especial
	
Printa_zero: ;printamos um zero após cada número
	MOV AH, 40H
	LEA DX, Zero
	MOV CX, 1
	INT 21H
	JC ERRO_ESCREVE_ZERO
	
	MOV [Bar_Code_Especial], 0
	MOV handle_arq_bar, BX
	MOV BX, handle_arq_txt
	JMP Funcao_Le_Arquivo_TXT

;========================================================================================================================

;calcula digito verificador e printa ele no .BAR, tem que zerar DI ao final e fazer o peso igual a 1
Calcula_Dig_Verificador: 
	MOV handle_arq_txt, BX
	LEA DI, Vet_Seq_Num
	MOV BX, [pos_vet]
	DEC BX 	; para não pegarmos a próxima posição do vetor, que está zerada, diminuímos em uma unidade a posicao
Loop_Calcula_Dig_Verificador: ;deve ser problema na hora de passar de linha
	CMP BX, -1
	JE Divide_Onze
	MOV AX, [DI+BX] ;multiplicamos o número na posicao atual do vetor pelo peso
	MUL Peso_Dig_Verificador
	ADD Dig_Verificador, AX	; adicionamos o valor ao dígito Verificador	
	MOV [DI+BX], 0 ; limpa atual posição do vetor
	INC BYTE PTR [Peso_Dig_Verificador]
	DEC BX
	JMP Loop_Calcula_Dig_Verificador
	
Divide_Onze:
	MOV BX, 11
	MOV AX, Dig_Verificador ; problema
	XOR DX, DX ;zeramos DX
	DIV BX
	MOV Dig_Verificador, DX ;o resto da divisão é o valor final do Dig_Verificador
	
Mensagem_Dig_verif:
	 ; Debug: Confirmação de cálculo
	CALL Mensagem_Calculo_Dig_Verif
	
    MOV AX, Dig_Verificador
	CMP AX, 10
	JE Dig_Verificador_10
    ADD AX, '0'; Converte para ASCII ('0' = 30h)
	MOV Dig_Verificador, AX
	
	MOV AH, 09H
	LEA DX, Dig_Verificador
	INT 21H
	JMP Loop_Dig_Verif
	
Dig_Verificador_10:
	MOV AH, 09H
	LEA DX, Dez
	INT 21H
	JMP Loop_Dig_Verif_part2
	
Loop_Dig_Verif:
	SUB Dig_Verificador, '0'
Loop_Dig_Verif_part2:
	LEA SI, BAR_CODES ; movemos o conteúdo do vetor BAR_CODES para SI
	CALL Subrotina_Dig_verif
	CMP [Bar_Code_Especial], 1
	JE Chama_Printa_Especial_Dig_Verif
	CALL Printa_Barcode
	JMP Zera_Variaveis_Dig_Verificador	
	
Subrotina_Dig_verif:
	MOV DX, Dig_Verificador ;já é um número, não está em ASCII, não precisamos 'convertê-lo' novamente
	CMP DX, 0
	JE Dig_Verif_Esp
	CMP DX, 9
	JE Dig_Verif_Esp
	CMP DX, 10
	JE Dig_Verif_Esp
	CMP DX, 0
	JE Pulo_Aux_Dig_verif ; fazemos isso de novo para garantir que dx não fique igual a -1
	
Loop_nsei_Dig_verif:
	CMP DX, 0
	JE Pulo_Aux_Dig_verif
	ADD SI, 7
	DEC DX
	JMP Loop_nsei_Dig_verif
	
Pulo_Aux_Dig_verif:
	RET	

Dig_Verif_Esp:
	MOV [Bar_Code_Especial], 1
	JMP Loop_nsei_Dig_verif
	
Chama_Printa_Especial_Dig_Verif:
	CALL Printa_Barcode_Especial
	
Zera_Variaveis_Dig_Verificador:
	MOV AH, 40H ; printamos o zero depois do dígito verificador
	MOV BX, handle_arq_bar
	LEA DX, Zero
	MOV CX, 1
	INT 21H
	MOV Dig_Verificador, 0
	MOV Peso_Dig_Verificador, 1
	MOV [pos_vet], 0
	MOV [Bar_Code_Especial], 0
	JMP Printa_SS
	
;================================================================================================================================

Proxima_Linha: ; handle está no .BAR
	MOV flag_fim_linha, 1
	ADD Count_Linha, 1
	CMP Count_Linha, 51
	JE First
	MOV SI, 0 ;zeramos para poder comparar com o STOP
	MOV flag_ss, 0
	CMP [Count_Num], 11
	JE Ignora_ate_CR
	MOV [Count_Num], 0
	MOV handle_arq_bar, BX
	MOV BX, handle_arq_txt
	JMP Funcao_Le_Arquivo_TXT

;=================================================================================================================================
	
Funcao_Compara_STOP: ;checamos se a próxima linha é STOP
	MOV AL, [BUFFER]
	CMP AL, [SI+strB]
	JNE Reset_Linha ; se não for STOP, começamos a ler a próxima linha do arquivo TXT
	;botar um cmp com nada, para caso a linha for em branco, ou com cr lf, pra ir pra próxima linha
	INC SI
	CMP SI, 4
	JE STOP_Encontrado
	JMP Funcao_Le_Arquivo_TXT

Reset_Linha:
	MOV flag_fim_linha, 0
	MOV SI, 0
	MOV handle_arq_txt, BX
	
	CALL Quebra_de_Linha
	
	MOV AH, 40H
	LEA DX, SS_codigo ;printamos o código ss no arquivo de barras
	MOV CX, 7
	INT 21H
	
	MOV flag_ss, 1
	
	MOV AH, 40H
	LEA DX, Zero ;escrevemos zero após o primeiro SS da linha
	MOV CX, 1
	INT 21H
	JC ERRO_ESCREVE_ZERO
	
	JMP Le_Sequencia_Num_2

;fechamos o arquivo de texto, printamos STOP no arquivo de barras, fechamos o arquivo de barras e finalizamos o programa
First:
	CALL Quebra_de_Linha
	JMP STOP_Encontrado

Quebra_de_Linha:
	MOV AH, 40H
	MOV BX, handle_arq_bar
	MOV CX, 2
	LEA DX, CR_LF ;vamos para a linha seguinte
	INT 21H
	JC ERRO_ESCRITA
	RET
	
STOP_Encontrado:
	MOV BX, handle_arq_txt
	CALL Funcao_Fecha_Arquivo
	JC ERRO_FECHAR_ARQUIVO_TXT
	CALL Quebra_de_Linha
	MOV AH, 40H
	MOV BX, handle_arq_bar
	LEA DX, strB ;printamos a palavra "STOP" no final do arquivo .BAR
	MOV CX, 4 ;note que a posição do cursor já está no início da linha inferior
	INT 21H
	CALL Funcao_Fecha_Arquivo
	JC ERRO_FECHAR_ARQUIVO_BAR
	JMP Fim_Programa


;=================================================================================================================================	
;Funções BarCode

Printa_Barcode: ;função para printar_barcode no arquivo de barras
	MOV AH, 40H
	MOV BX, handle_arq_bar
	LEA DX, [SI]
	MOV CX, 7
	INT 21H
	RET
	
Printa_Barcode_Especial:;usado para printar 0, 9 e 10, cujos barcodes possuem apenas 6 dígitos
	MOV AH, 40H
	MOV BX, handle_arq_bar
	LEA DX, [SI]
	MOV CX, 6
	INT 21H
	RET
	
Verifica_Caractere_Valido: ;função para definir se o caractere lido é válido ou inválido
	CMP DL, 0
	JB Rejeita_Caractere
	CMP DL, 10
	JA Rejeita_Caractere 
	
Confirma_Caractere:
	MOV AL, 1
	RET
	
Rejeita_Caractere:
	MOV AL, 0
	RET
	
Caractere_Invalido_Mostra_Mensagem:
	MOV AH, 40H
	MOV BX, handle_arq_bar
	LEA DX, strC
	MOV CX, 21
	INT 21H
	JC ERRO_ESCRITA
	MOV AH, 40H
	LEA DX, Zero ;escrevemos zero após o primeiro SS da linha
	MOV CX, 1
	INT 21H
	JC ERRO_ESCREVE_ZERO
	CALL Mensagem_Encontra_Caractere_Invalido
	MOV handle_arq_bar, BX
	MOV BX, handle_arq_txt
	JMP Funcao_Le_Arquivo_TXT

Max_Linha:
	; mensagem falando q excedeu o numero de linhas, pular todos os outros caracteres até o proximo cr lf
	MOV AH, 40H
	MOV BX, handle_arq_bar
	LEA DX, strD
	MOV CX, 69
	INT 21H
	JC ERRO_ESCRITA
	MOV AH, 40H
	LEA DX, Zero
	MOV CX, 1
	INT 21H
	MOV handle_arq_bar, BX
	MOV BX, handle_arq_txt
	CALL Mensagem_MAX_LINHA_Excedido
	JMP Calcula_Dig_Verificador

Ignora_ate_CR:
	MOV [flag_ignora], 1
	MOV handle_arq_bar, BX
	MOV BX, handle_arq_txt
	JMP Funcao_Le_Arquivo_TXT
Loop_Ignora_ate_CR:	
	MOV AL, [BUFFER]
	CMP AL, CR
	JE Nova_linha
	JMP Funcao_Le_Arquivo_TXT
	
Nova_Linha:
	MOV [flag_ignora], 0
	JMP Programa_Gerador
	
	.exit
end