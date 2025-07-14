/****************************************************************************** 
(c) 2023, 2024, 2025 Andre Reis - UFRGS - InPlace 
Module name : saci_pitanga
Description : SACI microprocessor, made by instantiating different modules
******************************************************************************/
module saci_pitanga(
    clk, rst,
    //OutAC, //OutPC, OutREM
    //, oselPC, oenPC, oselMEM, oenREM, owrite, oopULA, oenAC
    //, oDregPC, oQregPC, oPCm1, oQrem
    oEndMem_7s, oEndMem_MS,
    //, oOutMem, oDregAC, oQregAC
    oMem128_7s,
    oEA
    //oLED_rst,
    //oClock // LED para monitorar o clock
);
    input clk;        // relógio do sistema (clock)
    input rst;        // reset

    //output blk;        // saída de relógio (para piscar led)

    // Sinais de Dados
    //output [7:0] OutAC;   // sair o valor do acumulador para debugar
    //output [7:0] OutPC;   // sair o valor do PC para debugar
    //output [7:0] OutREM;   // sair o valor do REM para debugar
    //output [7:0] resultado;   // resultado da memoria, para debugar

    //output oselPC;
    //output oenPC;
    //output oselMEM;
    //output oenREM;
    //output owrite;
    //output oopULA;
    //output oenAC;
    //output oLED_rst;
    //output oClock; 

    output [2:0] oEA;
    //output [7:0] oDregPC; // entrada do PC
    //output [7:0] oQregPC; // saida do PC
    //output [7:0] oPCm1; // saida do incrementador
    //output [7:0] oQrem; // saida do REM
    output [6:0] oEndMem_7s; // endereço da memoria
    output oEndMem_MS;
    //output [7:0] oOutMem; // saida da memoria
    //output [7:0] oDregAC; // entrada do AC
    //output [7:0] oQregAC; // saida do AC
    output [6:0] oMem128_7s; // O que foi escrito na memória
    wire [7:0] wMem128;

    wire SelPC, EnPC, EnREM, SelMem, Write, OpULA, EnAC, z;
    assign z = 1'b0;
    wire [7:0] DregPC; // entrada do PC
    wire [7:0] QregPC; // saida do PC
    wire [7:0] PCm1; // saida do incrementador
    wire [7:0] Qrem; // saida do REM
    wire [7:0] EndMem; // endereço da memoria
    wire [7:0] OutMem; // saida da memoria
    wire [7:0] DregAC; // entrada do AC
    wire [7:0] QregAC; // saida do AC

    //assign OutAC=QregAC;
    //assign OutPC=QregPC;
    //assign OutREM=Qrem;

    display7seg disp_EndMem(.in(EndMem[3:0]), .out(oEndMem_7s));
    display7seg disp_Mem128(.in(wMem128[3:0]), .out(oMem128_7s));
    assign oEndMem_MS = EndMem[7];

    mais_um_pit incrementapc(
        .a(QregPC), 
        .s(PCm1)
    );

    mux21_8b_pit muxpc(
        .sel(SelPC), 
        .e1(PCm1), 
        .e0(OutMem), 
        .saida(DregPC)
    );

    mux21_8b_pit muxmemoria(
        .sel(SelMem), 
        .e1(QregPC), 
        .e0(Qrem), 
        .saida(EndMem)
    );

    reg8_pit REM(
        .clk(clk), 
        .rst(rst), 
        .set(z), 
        .enable(EnREM), 
        .d(OutMem), 
        .q(Qrem)
    );

    reg8_pit PC(
        .clk(clk), 
        .rst(rst), 
        .set(z), 
        .enable(EnPC), 
        .d(DregPC), 
        .q(QregPC)
    );
    
    reg8_pit AC(
        .clk(clk), 
        .rst(rst), 
        .set(z), 
        .enable(EnAC), 
        .d(DregAC), 
        .q(QregAC)
    );
    
    memoria_pit memoria_saci(
        .write(Write), 
        .clk(clk), 
        .rst(rst), 
        .address(EndMem), 
        .din(QregAC), 
        .dout(OutMem), 
        .oMem128(wMem128)
    );
    
    ula_pit ula_saci(
        .a(OutMem), 
        .b(QregAC), 
        .op(OpULA), 
        .s(DregAC)
    );
    
    wire[3:0] inst_temp = OutMem[7:4]; 
    controle_saci_pit cs(
        .clk(clk), 
        .rst(rst), 
        .inst_in(inst_temp), 
        .selPC(SelPC), 
        .enPC(EnPC), 
        .selMEM(SelMem), 
        .enREM(EnREM), 
        .write(Write), 
        .opULA(OpULA), 
        .enAC(EnAC), 
        .oEA(oEA)
    );

    //assign oselPC=SelPC;
    //assign oenPC=EnPC;
    //assign oselMEM=SelMem;
    //assign oenREM=EnREM;
    //assign owrite=Write;
    //assign oopULA=OpULA;
    //assign oenAC=EnAC;	

    //assign oDregPC=DregPC; // entrada do PC
    //assign oQregPC=QregPC; // saida do PC
    //assign oPCm1=PCm1; // saida do incrementador
    //assign oQrem=Qrem; // saida do REM
    //assign oEndMem=EndMem; // endereço da memoria
    //assign oOutMem=OutMem; // saida da memoria
    //assign oDregAC=DregAC; // entrada do AC
    //assign oQregAC=QregAC; // saida do AC

    //assign oLED_rst = rst; // LED acende quando reset está ativo
    //assign oClock = clk; // LED acende quando reset está ativo
endmodule


/****************************************************************************** 
(c) 2023, 2024, 2025 Andre Reis - UFRGS - InPlace 
Module name : controle_saci_pit
Description : This module is a (sequential) state machine to control SACI.
              One output is type Mealy. Other outputs are type Moore.
              As this version of SACI has only 4 instructions (LDA, ADD, STA, 
              HLT, they can be encoded with 2 bits). A translator is used to 
              translate the 4-bit codes to 2-bit codes in order to simplify
              the state machine by reducing the number of inputs.
******************************************************************************/
module controle_saci_pit(clk, rst, inst_in, selPC, enPC, selMEM, enREM, write, opULA, enAC, oEA);
    input clk;
    input rst;
    input [3:0]	inst_in;
    output	selPC;
    output	enPC;
    output	selMEM;
    output	enREM;
    output	write;
    output	opULA;
    output	enAC;
    output  [2:0] oEA;
	
    wire enable;
    wire [4:0] entradas_cc;
    wire [2:0] PE;
    wire [2:0] EA; // Estado atual da FSM
	
    //instancia do tradutor: não mexe que estraga: inicio
    nor (enable, EA[2], EA[1], EA[0]);
    wire [1:0] inst_temp;
    //instancia do tradutor: não mexe que estraga: meio
    trad_inst_pit tradutor(.clk(clk), .enable(enable), .inst_in(inst_in), .inst_out(inst_temp));
    //instancia do tradutor: não mexe que estraga: fim

    // A fins de nao extragar, nao foi mexido xD
    
    //vetor concatenado para dar tabelas iguais aos slides
    assign entradas_cc[4] = inst_temp[1]; // Corrigido para evitar erro de sintaxe
    assign entradas_cc[3] = inst_temp[0]; // Corrigido para evitar erro de sintaxe
    assign entradas_cc[2] = EA[2]; // Corrigido para evitar erro de sintaxe
    assign entradas_cc[1] = EA[1]; // Corrigido para evitar erro de sintaxe
    assign entradas_cc[0] = EA[0]; // Corrigido para evitar erro de sintaxe
    assign oEA=EA;
	 

    // Chamada do circuito CCPE
    ccpe circuito_ccpe(
        .PE(PE),
        .entradas(entradas_cc)
    );    

    // chamada do circuito de saída Mealy, com portas lógicas combinacionais
    saida_mealy circuito_enPC(
        .enPC(enPC), 
        .entradas_cc(entradas_cc)
    );
        
    // chamada do circuito de saída Moore, com portas lógicas combinacionais
    wire [5:0] saidas;	
    saidas_moore cc_saidas_moore(
        .EA(EA), 
        .saidas_moore(saidas)
    );
    
    //atribui as saidas, talvez parte do ccsaida
    buf(selPC, saidas[5]);
    buf(selMEM, saidas[4]);
    buf(enREM, saidas[3]);
    buf(write, saidas[2]);
    buf(opULA, saidas[1]);
    buf(enAC, saidas[0]);

    //chama o reg 3 direto, fazer o conteúdo do reg3 chamando três FFs
    reg3 registrador_estado(
        .clk(clk), 
        .rst(rst), 
        .EA(EA), 
        .PE(PE)
    );															
endmodule




/****************************************************************************** 
(c) 2023, 2024, 2025 Andre Reis - UFRGS - InPlace 
Module name : saida_mealy
Description : Combinational logic to generate Mealy output (enPC) based on 
              current state and instruction
******************************************************************************/
/*
    O módulo saida_mealy gera o sinal de controle do tipo Mealy (enPC).
    O enPC depende do estado atual da FSM e da instrução corrente.
    A lógica é implementada usando portas lógicas para as condições especificadas.
*/
module saida_mealy(enPC, entradas_cc);
    input [4:0] entradas_cc;
    output enPC;

    // Sinal de controle do tipo Mealy: depende do estado atual da FSM e do opcode da instrução.
    // enPC é ativado (1) apenas nos estados 000 (fetch/opcode) ou 001 (leitura do imediato/endereço),
    // e somente se a instrução NÃO for HLT (opcode diferente de 00).
    // Isso garante que o PC só avança durante busca/leitura, exceto quando a instrução é HLT (parada).

    wire opcode_lsb, opcode_msb, ea0, ea1, ea2;
    wire n_ea0, n_ea1, n_ea2;
    wire n_opcode_msb, n_opcode_lsb;
    wire not_hlt;
    wire hlt_instr;

    // entradas_cc[4:3] = opcode (HLT=00, STA=01, LDA=10, ADD=11)
    buf(opcode_lsb, entradas_cc[3]);
    buf(opcode_msb, entradas_cc[4]);
    
    // entradas_cc[2:0] = estado (EA)
    buf(ea0, entradas_cc[0]);
    buf(ea1, entradas_cc[1]);
    buf(ea2, entradas_cc[2]);

    // Detecta HLT (opcode == 00)
    // Se opcode_msb=0 e opcode_lsb=0, então é HLT.
    not(n_opcode_lsb, opcode_lsb);
    not(n_opcode_msb, opcode_msb);
    and(hlt_instr, n_opcode_msb, n_opcode_lsb);

    // Detecta estados 000 ou 001
    // Estado 000: fetch/opcode
    // Estado 001: leitura do imediato/endereço
    wire estado_000, estado_001, estado_000_001;
    not(n_ea0, ea0);
    not(n_ea1, ea1);
    not(n_ea2, ea2);
    
    // estado_000 = !ea2 & !ea1 & !ea0
    and(estado_000, n_ea2, n_ea1, n_ea0);

    // estado_001 = !ea2 & !ea1 & ea0
    and(estado_001, n_ea2, n_ea1, ea0);

    // estado_000_001 = estado_000 OR estado_001
    or(estado_000_001, estado_000, estado_001);

    // enPC = 1 apenas nos estados 000 ou 001, exceto para HLT
    wire enPC_temp;
    
    // not_htl = !hlt_instr
    not(not_hlt, hlt_instr);

    // enPC_temp = (estado_000 OR estado_001) AND not_hlt
    and(enPC_temp, estado_000_001, not_hlt);
    
    buf(enPC, enPC_temp);
endmodule

/****************************************************************************** 
(c) 2023, 2024, 2025 Andre Reis - UFRGS - InPlace 
Module name : ccpe (ccpe = calculo proximo estado)
Description : Combinational logic to calculate next state based on current 
              state and instruction
******************************************************************************/

/*
    O módulo ccpe calcula o próximo estado da FSM (Finite State Machine).
    A transição de estados depende do estado atual e da instrução corrente.
    Implementado usando portas lógicas para definir as regras de transição:
    000→001, 001→010/011/100, 010/011/100→000.
*/


//

module ccpe(PE, entradas);
    input [4:0] entradas;   // entradas de controle: [4:3] opcode, [2:0] EA
    output [2:0] PE;        // próximo estado (PE)
    // Conecta entradas aos fios internos


    wire e0, e1, e2, e3, e4;
    wire ne0, ne1, ne2, ne3, ne4;
	 
	 wire defaulted;
	 wire td_PE[2:0];
	 wire def[2:0];
	 wire nao_def[2:0];

    // Separar bits individuais
    buf(e0, entradas[0]);
    buf(e1, entradas[1]);
    buf(e2, entradas[2]);
    buf(e3, entradas[3]);
    buf(e4, entradas[4]);

    // Inversos
    not(ne0, e0);
    not(ne1, e1);
    not(ne2, e2);
    not(ne3, e3);
    not(ne4, e4);

    // -----------------------------------------------------
    // Mintermos nomeados
    wire m_01000, m_01001, m_10000, m_10001, m_11000, m_11001;
    
    and(m_01000, ne4,  e3,  ne2, ne1, ne0); // 01000
    and(m_01001, ne4,  e3,  ne2, ne1,  e0); // 01001
    and(m_10000,  e4, ne3, ne2, ne1, ne0);  // 10000
    and(m_10001,  e4, ne3, ne2, ne1,  e0);  // 10001
    and(m_11000,  e4,  e3, ne2, ne1, ne0);  // 11000
    and(m_11001,  e4,  e3, ne2, ne1,  e0);  // 11001

    // -----------------------------------------------------
    // PE[0] deve ser 1 apenas em:
    // 01000, 10000, 11000, 11001
    // (corrigido: removido 10001)
    or(td_PE[0], m_01000, m_10000, m_11000, m_11001);

    // PE[1] = 1 em: 10001, 11001
    or(td_PE[1], m_10001, m_11001);

    // PE[2] = 1 em: 01001
    or(td_PE[2], m_01001);
	 
	 // Mecanismo que calcula os casos default
	 
	 wire e0_2, e1_2, e2_2, e3_2, e4_2;
    wire ne0_2, ne1_2, ne2_2, ne3_2, ne4_2;
	 wire match;

    // Buffer inputs
    buf(e0_2, entradas[0]);
    buf(e1_2, entradas[1]);
    buf(e2_2, entradas[2]);
    buf(e3_2, entradas[3]);
    buf(e4_2, entradas[4]);

    // Inverses
    not(ne0_2, e0_2);
    not(ne1_2, e1_2);
    not(ne2_2, e2_2);
    not(ne3_2, e3_2);
    not(ne4_2, e4_2);

    // Define all 20 minterms (one for each valid entradas)
    wire m0, m1, m2, m3, m4, m5, m6, m7, m8, m9;
    wire m10, m11, m12, m13, m14, m15, m16, m17, m18, m19;

    and(m0,  ne4_2, ne3_2, ne2_2, ne1_2, ne0_2); // 00000
    and(m1,  ne4_2, ne3_2, ne2_2, ne1_2,  e0_2); // 00001
    and(m2,  ne4_2, ne3_2, ne2_2,  e1_2, ne0_2); // 00010
    and(m3,  ne4_2, ne3_2, ne2_2,  e1_2,  e0_2); // 00011
    and(m4,  ne4_2, ne3_2,  e2_2, ne1_2, ne0_2); // 00100

    and(m5,  ne4_2,  e3_2, ne2_2, ne1_2, ne0_2); // 01000
    and(m6,  ne4_2,  e3_2, ne2_2, ne1_2,  e0_2); // 01001
    and(m7,  ne4_2,  e3_2, ne2_2,  e1_2, ne0_2); // 01010
    and(m8,  ne4_2,  e3_2, ne2_2,  e1_2,  e0_2); // 01011
    and(m9,  ne4_2,  e3_2,  e2_2, ne1_2, ne0_2); // 01100

    and(m10,  e4_2, ne3_2, ne2_2, ne1_2, ne0_2); // 10000
    and(m11,  e4_2, ne3_2, ne2_2, ne1_2,  e0_2); // 10001
    and(m12,  e4_2, ne3_2, ne2_2,  e1_2, ne0_2); // 10010
    and(m13,  e4_2, ne3_2, ne2_2,  e1_2,  e0_2); // 10011
    and(m14,  e4_2, ne3_2,  e2_2, ne1_2, ne0_2); // 10100

    and(m15,  e4_2,  e3_2, ne2_2, ne1_2, ne0_2); // 11000
    and(m16,  e4_2,  e3_2, ne2_2, ne1_2,  e0_2); // 11001
    and(m17,  e4_2,  e3_2, ne2_2,  e1_2, ne0_2); // 11010
    and(m18,  e4_2,  e3_2, ne2_2,  e1_2,  e0_2); // 11011
    and(m19,  e4_2,  e3_2,  e2_2, ne1_2, ne0_2); // 11100

    // OR all valid minterms to get match signal
    or(match, m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15, m16, m17, m18, m19);
	 not(defaulted, match);
	 
	 
	 
	 // Mecanismo que aplica os valores default
	 //b0									<= tem que virar 1 se defaulted = 1
	 and(def[0], defaulted, 1'b1);
	 and(nao_def[0], match, td_PE[0]);
	 or(PE[0], def[0], nao_def[0]);
	 
	 //b1								<= tem que virar 0 se defaulted = 1
	 and(def[1], defaulted, 1'b0);
	 and(nao_def[1], match, td_PE[1]);
	 or(PE[1], def[1], nao_def[1]);
	 
	 //b2								<= tem que virar 1 se defaulted = 1
	 and(def[2], defaulted, 1'b1);
	 and(nao_def[2], match, td_PE[2]);
	 or(PE[2], def[2], nao_def[2]);
	 
	 

endmodule

module trad_inst_pit(clk, enable, inst_in, inst_out);
    input clk;
    input enable;
    input [3:0] inst_in;
    output [1:0] inst_out;

    wire [1:0] inst_temp_variavel;
    wire [1:0] inst_temp_registrado;
    reg [1:0] inst_reg;

    /*
        Tradução de instrução de 4 bits para 2 bits usando apenas portas lógicas.
        Tabela verdade:
        - HLT: 1111 → 00
        - STA: 0001 → 01
        - LDA: 0010 → 10
        - ADD: 0011 → 11
        - Default: qualquer outro → 00
    */
    wire n0, n1, n2, n3;
    not(n0, inst_in[0]);
    not(n1, inst_in[1]);
    not(n2, inst_in[2]);
    not(n3, inst_in[3]);

    // Detecta cada instrução
    wire is_hlt, is_sta, is_lda, is_add;
    // HLT: inst_in == 1111
    and(is_hlt, inst_in[3], inst_in[2], inst_in[1], inst_in[0]);
    // STA: inst_in == 0001
    and(is_sta, n3, n2, n1, inst_in[0]);
    // LDA: inst_in == 0010
    and(is_lda, n3, n2, inst_in[1], n0);
    // ADD: inst_in == 0011
    and(is_add, n3, n2, inst_in[1], inst_in[0]);

    // Saída combinacional para cada bit
    // inst_temp_variavel[1] = LDA ou ADD
    or(inst_temp_variavel[1], is_lda, is_add);
    // inst_temp_variavel[0] = STA ou ADD
    or(inst_temp_variavel[0], is_sta, is_add);

    // Default: se nenhuma instrução reconhecida, saída é 00
    // (já garantido pois as saídas só ativam para instruções válidas)

    assign inst_temp_registrado = inst_reg;
    assign inst_out = (enable) ? inst_temp_variavel : inst_temp_registrado;

    always@(posedge clk) begin
        if (enable)
            inst_reg <= inst_temp_variavel;
    end
endmodule

/****************************************************************************** 
(c) 2023, 2024, 2025 Andre Reis - UFRGS - InPlace 
Module name : ula_pit
Description : This is a ULA that makes only two operations. It is a 
              combinational circuit. The operations are s=a+b when op=1
              and s=a when op=0
******************************************************************************/
//ula ula_saci(.a(), .b(), .op(), .s());
module ula_pit(a, b, op, s);
    input [7:0]	a;
    input [7:0]	b;
    input op;
    output[7:0]	s;


    wire [7:0] soma;
    wire dummy_carry;
    // guarda a soma de a e b na variável soma
    somador_8b somador(
        .a(a), 
        .b(b), 
        .saida(soma),
        .c_out(dummy_carry) // Conectado a dummy para evitar warning
    );
    // retorna soma se op=1, ou a se op=0
    mux21_8b_pit mux_ula(
        .sel(op),
        .e1(soma),
        .e0(a),
        .saida(s)
    );
endmodule

/****************************************************************************** 
(c) 2023, 2024, 2025 Andre Reis - UFRGS - InPlace 
Module name : memoria_pit
Description : 1) This module is partly combinational, partly sequential.
              2) The program ROM is combinational, it comes from module 
                rom_prog_pit, which is instantiated.
              3) The program RAM is sequential, it is made by 
                instantiating a 8-bit register defined in module reg8_pit
              4) The ROM and RAM are multiplexed by the highes bit in memory
                address. This is done by instantiating mux21_8b_pit
******************************************************************************/	  
module memoria_pit(
    input write,
    input clk,
    input rst,
    input [7:0] address,      // 8-bit register input
    input [7:0] din,
    output [7:0] dout,
    output [7:0] oMem128
);   // 8-bit register output

	wire [7:0] saida_rom;
	wire [7:0] saida_ram;
	wire enable;
	wire zero, nrst;
	not (nrst, rst);
	and (zero, nrst, rst);
	and(enable, address[7], write);
   
    rom_prog_pit rp(
        .address(address), 
        .content(saida_rom)
    );
	
    reg8_pit r(
        .d(din), 
        .q(saida_ram), 
        .clk(clk), 
        .rst(rst), 
        .set(1'b0), // FIX: Provide constant value for set port
        .enable(enable)
    );
	
    mux21_8b_pit m8b(
        .e0(saida_rom), 
        .e1(saida_ram), 
        .sel(address[7]), 
        .saida(dout)
    );
	
	assign oMem128 = saida_ram;
endmodule


/****************************************************************************** 
(c) 2023, 2024, 2025 Andre Reis - UFRGS - InPlace 
Module name : rom_prog_pit
Description : This is a ROM containing the program that adds 5+5 and stores 
              the result in position 128. It is a combinational circuit.
              It is made using minterms.
******************************************************************************/
/*
    ROM (Read-Only Memory) programática para o SACI:
    - Esta ROM armazena um programa fixo, implementado apenas com portas lógicas.
    - O programa é codificado usando minterms, ou seja, cada linha da ROM é ativada
      por uma combinação específica dos bits do endereço.
    - O endereço é de 8 bits, permitindo até 256 posições, mas apenas algumas
      são usadas para o programa exemplo (somar 5+5 e guardar em 128).

    Estrutura:
    1. Os sinais naddress[i] são os bits invertidos do endereço, usados para formar minterms.
    2. Os minterms são combinações AND de três bits do endereço (aqui, address[2:0]),
       representando as 8 possíveis linhas do programa.
    3. Cada bit da saída 'content' é formado por combinações OR/AND/BUF dos minterms,
       definindo o dado lido para cada endereço.
    4. O uso de portas lógicas para implementar a ROM é didático e hardware-realista:
       cada linha da ROM é ativada por um minterm, e cada saída é formada por lógica combinacional.
*/
module rom_prog_pit(
    input [7:0] address,        // 8-bit register input
    output [7:0] content        // 8-bit register output
);    

    wire [7:0] naddress; // Vetor com os bits invertidos do endereço
    wire [7:0] minterm;  // Vetor de minterms, cada um ativado para uma combinação única de address[2:0]

    // Inverte cada bit do endereço para facilitar a construção dos minterms
    not(naddress[0], address[0]);
    not(naddress[1], address[1]);
    not(naddress[2], address[2]);
    not(naddress[3], address[3]);
    not(naddress[4], address[4]);
    not(naddress[5], address[5]);
    not(naddress[6], address[6]);
    not(naddress[7], address[7]);

    /*
        Os minterms abaixo são gerados para as 8 combinações possíveis de address[2:0]:
        - Cada minterm é ativado apenas para uma combinação específica dos 3 bits menos significativos do endereço.
        - Exemplo: minterm[0] = address[2:0] == 000
                   minterm[1] = address[2:0] == 001
                   ...
                   minterm[7] = address[2:0] == 111
    */
    and(minterm[0], naddress[2], naddress[1], naddress[0]); // 000
    and(minterm[1], naddress[2], naddress[1],  address[0]); // 001
    and(minterm[2], naddress[2],  address[1], naddress[0]); // 010
    and(minterm[3], naddress[2],  address[1],  address[0]); // 011
    and(minterm[4],  address[2], naddress[1], naddress[0]); // 100
    and(minterm[5],  address[2], naddress[1],  address[0]); // 101
    and(minterm[6],  address[2],  address[1], naddress[0]); // 110
    and(minterm[7],  address[2],  address[1],  address[0]); // 111

    /*
        Cada bit de saída (content[0] a content[7]) é formado por uma combinação dos minterms.
        - Isso define o valor da ROM para cada endereço.
        - O uso de portas OR permite que um bit de saída seja ativado por múltiplos minterms (endereços).
        - O mapeamento abaixo representa o programa gravado na ROM, que pode ser instruções, dados, etc.
    */

    // content[0]: Ativado para minterm[1], minterm[3], minterm[7]
    or(content[0], minterm[1], minterm[3], minterm[7]);
    or(content[1], minterm[1], minterm[3]);
    or(content[2], minterm[1], minterm[3], minterm[7]);

    and(content[3], address[0], naddress[0]); //none
    or(content[4], minterm[2], minterm[4], minterm[6]);
    or(content[5], minterm[0], minterm[2], minterm[6]);
    
    buf(content[6], minterm[6]);
    or(content[7], minterm[5], minterm[6]);

    /*
        - Esta ROM é totalmente combinacional, sem uso de memória física.
        - O conteúdo é definido por minterms, que são ativados para endereços específicos.
        - Cada bit de saída pode ser entendido como uma função booleana dos bits do endereço.
        - O programa gravado pode ser alterado modificando os minterms e as combinações de OR.
        - Este tipo de implementação é útil para fins didáticos e para circuitos pequenos.
    */
endmodule

/****************************************************************************** 
(c) 2023, 2024, 2025 Andre Reis - UFRGS - InPlace 
Module name : mais_um_pit
Description : This module is a combinational circuit that increments a 8-bit
              value received as input
******************************************************************************/	  	  
module mais_um_pit(     // f(x) = x + 1
    input [7:0] a,                // Entrada de 8 bits
    output [7:0] s               // Saída incrementada
    // output overflow           // Sinal de overflow (carry do bit 7) - não usado
);
    // Instancia o somador de 8 bits, somando 'a' com 1
    wire dummy_carry; // Conectado a dummy para evitar warning
    somador_8b somador_incrementa(
        .a(a),
        .b(8'b00000001), // constante 1 para incrementar
        .saida(s),
        .c_out(dummy_carry) // Conectado a dummy para evitar warning
    );
endmodule


/****************************************************************************** 
(c) 2023, 2024, 2025 Andre Reis - UFRGS - InPlace 
Module name : mux21_8b_pit
Description : This module is a 2-input multiplexer. Data is 8-bit wide.
              It is a combinational circuit. 
******************************************************************************/
//mux21_8b muxpc(.sel(), .e1(), .e0(), .saida(fio_pctem_1));
module mux21_8b_pit(
    input sel,           // Sinal de seleção do mux
    input [7:0] e1,      // Entrada 1 (selecionada se sel=1)
    input [7:0] e0,      // Entrada 0 (selecionada se sel=0)
    output [7:0] saida   // Saída multiplexada
);
    wire sel_n;
    not(sel_n, sel); // sel_n = ~sel

    // Para cada bit i:
    // saida[i] = (e0[i] AND ~sel) OR (e1[i] AND sel)
    // Isso implementa um mux 2:1 bit a bit

    // Bit 0
    wire saida_0_0, saida_1_0;
    and(saida_0_0, e0[0], sel_n); // e0[0] quando sel=0
    and(saida_1_0, e1[0], sel);   // e1[0] quando sel=1
    or(saida[0], saida_0_0, saida_1_0);

    // Bit 1
    wire saida_0_1, saida_1_1;
    and(saida_0_1, e0[1], sel_n);
    and(saida_1_1, e1[1], sel);
    or(saida[1], saida_0_1, saida_1_1);

    // Bit 2
    wire saida_0_2, saida_1_2;
    and(saida_0_2, e0[2], sel_n);
    and(saida_1_2, e1[2], sel);
    or(saida[2], saida_0_2, saida_1_2);

    // Bit 3
    wire saida_0_3, saida_1_3;
    and(saida_0_3, e0[3], sel_n);
    and(saida_1_3, e1[3], sel);
    or(saida[3], saida_0_3, saida_1_3);

    // Bit 4
    wire saida_0_4, saida_1_4;
    and(saida_0_4, e0[4], sel_n);
    and(saida_1_4, e1[4], sel);
    or(saida[4], saida_0_4, saida_1_4);

    // Bit 5
    wire saida_0_5, saida_1_5;
    and(saida_0_5, e0[5], sel_n);
    and(saida_1_5, e1[5], sel);
    or(saida[5], saida_0_5, saida_1_5);

    // Bit 6
    wire saida_0_6, saida_1_6;
    and(saida_0_6, e0[6], sel_n);
    and(saida_1_6, e1[6], sel);
    or(saida[6], saida_0_6, saida_1_6);

    // Bit 7
    wire saida_0_7, saida_1_7;
    and(saida_0_7, e0[7], sel_n);
    and(saida_1_7, e1[7], sel);
    or(saida[7], saida_0_7, saida_1_7);
endmodule

/****************************************************************************** 
(c) 2023, 2024, 2025 Andre Reis - UFRGS - InPlace 
Module name : reg8_pit
Description : This module is a 8-bit register. It is a sequential circuit.
******************************************************************************/	  
//reg8 REM(.clk(), .rst(), .set(), .enable(), .d(), .q());
module reg8_pit(
    input clk,
    input rst,
    input set,
    input enable,
    input [7:0] d,
    output [7:0] q
);
    // Registrador de 8 bits usando flip-flops D com lógica de controle
    wire rst_n, set_n, enable_n;
    not(rst_n, rst);
    not(set_n, set);
    not(enable_n, enable);

    // Bit 0
    wire rst_val0, set_val0, enable_val0, hold_val0, next_q0, q_inv_unused0;
    and(rst_val0, rst, 1'b0);
    and(set_val0, set, 1'b1);
    and(enable_val0, enable, d[0]);
    and(hold_val0, rst_n, set_n, enable_n, q[0]);
    or(next_q0, rst_val0, set_val0, enable_val0, hold_val0);
    d_flipflop reg_bit0(
        .clk(clk),
        .rst(rst),
        .entrada(next_q0),
        .saida_q(q[0]),
        .saida_q_invertido(q_inv_unused0)
    );

    // Bit 1
    wire rst_val1, set_val1, enable_val1, hold_val1, next_q1, q_inv_unused1;
    and(rst_val1, rst, 1'b0);
    and(set_val1, set, 1'b1);
    and(enable_val1, enable, d[1]);
    and(hold_val1, rst_n, set_n, enable_n, q[1]);
    or(next_q1, rst_val1, set_val1, enable_val1, hold_val1);
    d_flipflop reg_bit1(
        .clk(clk),
        .rst(rst),
        .entrada(next_q1),
        .saida_q(q[1]),
        .saida_q_invertido(q_inv_unused1)
    );

    // Bit 2
    wire rst_val2, set_val2, enable_val2, hold_val2, next_q2, q_inv_unused2;
    and(rst_val2, rst, 1'b0);
    and(set_val2, set, 1'b1);
    and(enable_val2, enable, d[2]);
    and(hold_val2, rst_n, set_n, enable_n, q[2]);
    or(next_q2, rst_val2, set_val2, enable_val2, hold_val2);
    d_flipflop reg_bit2(
        .clk(clk),
        .rst(rst),
        .entrada(next_q2),
        .saida_q(q[2]),
        .saida_q_invertido(q_inv_unused2)
    );

    // Bit 3
    wire rst_val3, set_val3, enable_val3, hold_val3, next_q3, q_inv_unused3;
    and(rst_val3, rst, 1'b0);
    and(set_val3, set, 1'b1);
    and(enable_val3, enable, d[3]);
    and(hold_val3, rst_n, set_n, enable_n, q[3]);
    or(next_q3, rst_val3, set_val3, enable_val3, hold_val3);
    d_flipflop reg_bit3(
        .clk(clk),
        .rst(rst),
        .entrada(next_q3),
        .saida_q(q[3]),
        .saida_q_invertido(q_inv_unused3)
    );

    // Bit 4
    wire rst_val4, set_val4, enable_val4, hold_val4, next_q4, q_inv_unused4;
    and(rst_val4, rst, 1'b0);
    and(set_val4, set, 1'b1);
    and(enable_val4, enable, d[4]);
    and(hold_val4, rst_n, set_n, enable_n, q[4]);
    or(next_q4, rst_val4, set_val4, enable_val4, hold_val4);
    d_flipflop reg_bit4(
        .clk(clk),
        .rst(rst),
        .entrada(next_q4),
        .saida_q(q[4]),
        .saida_q_invertido(q_inv_unused4)
    );

    // Bit 5
    wire rst_val5, set_val5, enable_val5, hold_val5, next_q5, q_inv_unused5;
    and(rst_val5, rst, 1'b0);
    and(set_val5, set, 1'b1);
    and(enable_val5, enable, d[5]);
    and(hold_val5, rst_n, set_n, enable_n, q[5]);
    or(next_q5, rst_val5, set_val5, enable_val5, hold_val5);
    d_flipflop reg_bit5(
        .clk(clk),
        .rst(rst),
        .entrada(next_q5),
        .saida_q(q[5]),
        .saida_q_invertido(q_inv_unused5)
    );

    // Bit 6
    wire rst_val6, set_val6, enable_val6, hold_val6, next_q6, q_inv_unused6;
    and(rst_val6, rst, 1'b0);
    and(set_val6, set, 1'b1);
    and(enable_val6, enable, d[6]);
    and(hold_val6, rst_n, set_n, enable_n, q[6]);
    or(next_q6, rst_val6, set_val6, enable_val6, hold_val6);
    d_flipflop reg_bit6(
        .clk(clk),
        .rst(rst),
        .entrada(next_q6),
        .saida_q(q[6]),
        .saida_q_invertido(q_inv_unused6)
    );

    // Bit 7
    wire rst_val7, set_val7, enable_val7, hold_val7, next_q7, q_inv_unused7;
    and(rst_val7, rst, 1'b0);
    and(set_val7, set, 1'b1);
    and(enable_val7, enable, d[7]);
    and(hold_val7, rst_n, set_n, enable_n, q[7]);
    or(next_q7, rst_val7, set_val7, enable_val7, hold_val7);
    d_flipflop reg_bit7(
        .clk(clk),
        .rst(rst),
        .entrada(next_q7),
        .saida_q(q[7]),
        .saida_q_invertido(q_inv_unused7)
    );
endmodule


// Registrador de 3 bits com reset asassíncrono
// valores registrados na borda de subida do clock
// EA inicia em 000 após reset
/*module reg3(clk, rst, EA, PE);
    input clk;
    input rst;
    input [2:0] PE;
    output [2:0] EA;

    // Garantia: EA sempre inicia em 000 após reset
    // Reset assincrono força todos os bits para zero
    wire ea0_wire, ea1_wire, ea2_wire;
    wire ea0_n, ea1_n, ea2_n;

    d_flipflop ff0(
        .clk(clk),
        .rst(rst),
        .entrada(PE[0]),
        .saida_q(ea0_wire),
        .saida_q_invertido(ea0_n)
    );

    d_flipflop ff1(
        .clk(clk),
        .rst(rst),
        .entrada(PE[1]),
        .saida_q(ea1_wire),
        .saida_q_invertido(ea1_n)
    );
    
    d_flipflop ff2(
        .clk(clk),
        .rst(rst),
        .entrada(PE[2]),
        .saida_q(ea2_wire),
        .saida_q_invertido(ea2_n)
    );

    // Adiciona buffers para as saídas EA
    buf(EA[0], ea0_wire);
    buf(EA[1], ea1_wire);
    buf(EA[2], ea2_wire);
    // Após reset, EA = 000 garantido
endmodule
*/


/*******************************************************************************
(c) 2023, 2024, 2025 Andre Reis - UFRGS - InPlace 
Module name : reg3_pit
Description : 3-bit register with asynchronous reset
*******************************************************************************/

// O registrador baseado em flip-flops D nao compilava na placa pitanga
// mas estava funcionando corretamente quando era o unico modulo
// O bug provavelmente é na compilacao do verilog da placa pitanga
module reg3(
    input clk,
    input rst,
    input [2:0] PE,
    output [2:0] EA
);
    reg [2:0] estado;

    always @(posedge clk or posedge rst) begin
        if (rst)
            estado <= 3'b000;
        else
            estado <= PE;
    end

    assign EA = estado;
endmodule




// flip-flop tipo D com reset assíncrono
// Este módulo foi feito como always @(posedge clk or posedge rst) para poder simular na plataforma Pitanga.
// O reset assíncrono é ativado quando rst = 1, e a saída q é zerada.
// Quando rst = 0, a saída q recebe o valor de entrada na borda de subida do clock (posedge clk).
module d_flipflop(
    input clk,
    input rst,
    input entrada,
    output reg saida_q,
    output saida_q_invertido
);
    assign saida_q_invertido = ~saida_q;

    always @(posedge clk or posedge rst) begin
        if (rst)
            saida_q <= 1'b0;
        else
            saida_q <= entrada;
    end
endmodule

// Somador de 8 bits usando full adders
module somador_8b(
    input [7:0] a,      // Primeiro operando de 8 bits
    input [7:0] b,      // Segundo operando de 8 bits
    output [7:0] saida, // Soma de 8 bits
    output c_out        // Carry de saída (overflow)
);
    wire [7:0] carry;

    // Bit 0 (LSB)
    full_adder fa0(
        .a(a[0]),
        .b(b[0]),
        .c_in(1'b0),
        .saida(saida[0]),
        .c_out(carry[0])
    );
    // Bit 1
    full_adder fa1(
        .a(a[1]),
        .b(b[1]),
        .c_in(carry[0]),
        .saida(saida[1]),
        .c_out(carry[1])
    );
    // Bit 2
    full_adder fa2(
        .a(a[2]),
        .b(b[2]),
        .c_in(carry[1]),
        .saida(saida[2]),
        .c_out(carry[2])
    );
    // Bit 3
    full_adder fa3(
        .a(a[3]),
        .b(b[3]),
        .c_in(carry[2]),
        .saida(saida[3]),
        .c_out(carry[3])
    );
    // Bit 4
    full_adder fa4(
        .a(a[4]),
        .b(b[4]),
        .c_in(carry[3]),
        .saida(saida[4]),
        .c_out(carry[4])
    );
    // Bit 5
    full_adder fa5(
        .a(a[5]),
        .b(b[5]),
        .c_in(carry[4]),
        .saida(saida[5]),
        .c_out(carry[5])
    );
    // Bit 6
    full_adder fa6(
        .a(a[6]),
        .b(b[6]),
        .c_in(carry[5]),
        .saida(saida[6]),
        .c_out(carry[6])
    );
    // Bit 7 (MSB)
    full_adder fa7(
        .a(a[7]),
        .b(b[7]),
        .c_in(carry[6]),
        .saida(saida[7]),
        .c_out(c_out)
    );
endmodule



// Full Adder 
module full_adder(
    input a,        // Primeiro bit de entrada
    input b,        // Segundo bit de entrada
    input c_in,     // Carry de entrada
    output saida,   // Soma
    output c_out    // Carry de saída
);
    // Soma: a XOR b XOR c_in -> poderia ser xor3(a, b, c_in)
    wire xor1;
    xor(xor1, a, b);
    xor(saida, xor1, c_in);

    // Carry out: (a AND b) OR (a AND c_in) OR (b AND c_in) -> poderia ser maj(a, b, c_in)
    wire ab, ac, bc;
    and(ab, a, b);
    and(ac, a, c_in);
    and(bc, b, c_in);
    or(c_out, ab, ac, bc);
endmodule


/****************************************************************************** 
(c) 2023, 2024, 2025 Andre Reis - UFRGS - InPlace 
Module name : display7seg
Description : Converts 4-bits values to be shown as hexa in the 7-segments 
              display. It is a combinational circuit.
******************************************************************************/	  
module display7seg(in, out);
    input [3:0]	in;
    output[6:0]	out;
    // Descrição da arquitetura
    assign out =
        (in == 4'b0000)  ?   7'b1111110:
        (in == 4'b0001)  ?   7'b0110000:
        (in == 4'b0010)  ?   7'b1101101:
        (in == 4'b0011)  ?   7'b1111001:
                
        (in == 4'b0100)  ?   7'b0110011:
        (in == 4'b0101)  ?   7'b1011011:
        (in == 4'b0110)  ?   7'b1011111:
        (in == 4'b0111)  ?   7'b1110000:
                
        (in == 4'b1000)  ?   7'b1111111:
        (in == 4'b1001)  ?   7'b1111011:
        (in == 4'b1010)  ?   7'b1110111:
        (in == 4'b1011)  ?   7'b0011111:
                
        (in == 4'b1100)  ?   7'b1001110:
        (in == 4'b1101)  ?   7'b0111101:
        (in == 4'b1110)  ?   7'b1001111:
            7'b1000111; 
endmodule


/*
    O módulo saidas_moore gera os sinais de controle do tipo Moore.

    Sinais de controle Moore são sinais que dependem apenas do estado atual da máquina de estados (FSM),
    e não das entradas externas. Ou seja, para cada estado da FSM, existe uma combinação fixa de sinais de controle
    que comandam o funcionamento dos blocos do processador (ex: habilitar escrita, selecionar registrador, ativar ULA, etc).

    Cada bit do vetor sinais_controle representa um comando específico do datapath.
    Por exemplo:
      - sinais_controle[5]: seleciona o Program Counter (selPC)
      - sinais_controle[4]: seleciona a memória (selMEM)
      - sinais_controle[3]: habilita o registrador de endereço de memória (enREM)
      - sinais_controle[2]: habilita escrita na memória (mem <- acc).
      - sinais_controle[1]: seleciona operação da ULA (opULA)
      - sinais_controle[0]: habilita escrita no acumulador (enAC)
    A lógica Moore garante que esses sinais mudam apenas quando o estado da FSM muda, tornando o circuito mais previsível.
    Cada bit de sinais_controle usando portas lógicas é definido conforme a tabela verdade do seu projeto.

    Resumindo:
    - sinais_controle = sinais que controlam o hardware, derivados apenas do estado atual da FSM.
    - O próximo estado é calculado em outro módulo (ccpe).
*/


module saidas_moore(
    input [2:0] EA,     // Estado atual da FSM (EA)
    output [5:0] saidas_moore  // {selPC, selMEM, enREM, write, opULA, enAC}
);
    wire ea0, ea1, ea2;
    wire nea0, nea1, nea2;

    // Separar bits da entrada
    buf(ea0, EA[0]);
    buf(ea1, EA[1]);
    buf(ea2, EA[2]);

    // Inversos
    not(nea0, ea0);
    not(nea1, ea1);
    not(nea2, ea2);

    // Detectar estados válidos
    wire st_000, st_001, st_010, st_011, st_100;

    and(st_000, nea2, nea1, nea0); // EA = 000
    and(st_001, nea2, nea1,  ea0); // EA = 001
    and(st_010, nea2,  ea1, nea0); // EA = 010
    and(st_011, nea2,  ea1,  ea0); // EA = 011
    and(st_100,  ea2, nea1, nea0); // EA = 100

    // ---------------------------------------------------
    // saidas_moore[5] = 1 nos estados válidos
    or(saidas_moore[5], st_000, st_001, st_010, st_011, st_100);

    // saidas_moore[4] = 1 apenas nos estados 000 e 001
    or(saidas_moore[4], st_000, st_001);

    // saidas_moore[3] = 1 apenas no estado 001
    or(saidas_moore[3], st_001);

    // saidas_moore[2] = 1 apenas no estado 100 
    or(saidas_moore[2], st_100);

    // saidas_moore[1] = 1 nos estados 011 
    or(saidas_moore[1], st_011);

    // saidas_moore[0] = 1 nos estados 010 e 011
    or(saidas_moore[0], st_010, st_011);
	 
	 
endmodule