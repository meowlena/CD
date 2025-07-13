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
    oEA,
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
        .cen(EnREM), 
        .d(OutMem), 
        .q(Qrem)
    );

    reg8_pit PC(
        .clk(clk), 
        .rst(rst), 
        .set(z), 
        .cen(EnPC), 
        .d(DregPC), 
        .q(QregPC)
    );
    
    reg8_pit AC(
        .clk(clk), 
        .rst(rst), 
        .set(z), 
        .cen(EnAC), 
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
Module name : mais_um_pit
Description : This module is a combinational circuit that increments a 8-bit
              value received as input
******************************************************************************/	  	  
module mais_um_pit(
    input [7:0] a,                // Entrada de 8 bits
    output [7:0] s               // Saída incrementada
    // output overflow           // Sinal de overflow (carry do bit 7) - não usado
);
    // Instancia o somador de 8 bits, somando 'a' com 1
    wire dummy_carry; // Conectado a dummy para evitar warning
    somador_8b somador_incrementa(
        .a(a),
        .b(8'b00000001), // constante 1 para incrementar
        .soma(s),
        .carry_out(dummy_carry) // Conectado a dummy para evitar warning
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
//reg8 REM(.clk(), .rst(), .set(), .cen(), .d(), .q());
module reg8_pit(
    input clk,
    input rst,
    input set,
    input cen,
    input [7:0] d,
    output [7:0] q
);
    // Registrador de 8 bits usando flip-flops D com lógica de controle
    wire rst_n, set_n, cen_n;
    not(rst_n, rst);
    not(set_n, set);
    not(cen_n, cen);

    // Bit 0
    wire rst_val0, set_val0, cen_val0, hold_val0, next_q0, q_inv_unused0;
    and(rst_val0, rst, 1'b0);
    and(set_val0, set, 1'b1);
    and(cen_val0, cen, d[0]);
    and(hold_val0, rst_n, set_n, cen_n, q[0]);
    or(next_q0, rst_val0, set_val0, cen_val0, hold_val0);
    d_flipflop reg_bit0(
        .clk(clk),
        .rst(rst),
        .entrada(next_q0),
        .saida_q(q[0]),
        .saida_q_invertido(q_inv_unused0)
    );

    // Bit 1
    wire rst_val1, set_val1, cen_val1, hold_val1, next_q1, q_inv_unused1;
    and(rst_val1, rst, 1'b0);
    and(set_val1, set, 1'b1);
    and(cen_val1, cen, d[1]);
    and(hold_val1, rst_n, set_n, cen_n, q[1]);
    or(next_q1, rst_val1, set_val1, cen_val1, hold_val1);
    d_flipflop reg_bit1(
        .clk(clk),
        .rst(rst),
        .entrada(next_q1),
        .saida_q(q[1]),
        .saida_q_invertido(q_inv_unused1)
    );

    // Bit 2
    wire rst_val2, set_val2, cen_val2, hold_val2, next_q2, q_inv_unused2;
    and(rst_val2, rst, 1'b0);
    and(set_val2, set, 1'b1);
    and(cen_val2, cen, d[2]);
    and(hold_val2, rst_n, set_n, cen_n, q[2]);
    or(next_q2, rst_val2, set_val2, cen_val2, hold_val2);
    d_flipflop reg_bit2(
        .clk(clk),
        .rst(rst),
        .entrada(next_q2),
        .saida_q(q[2]),
        .saida_q_invertido(q_inv_unused2)
    );

    // Bit 3
    wire rst_val3, set_val3, cen_val3, hold_val3, next_q3, q_inv_unused3;
    and(rst_val3, rst, 1'b0);
    and(set_val3, set, 1'b1);
    and(cen_val3, cen, d[3]);
    and(hold_val3, rst_n, set_n, cen_n, q[3]);
    or(next_q3, rst_val3, set_val3, cen_val3, hold_val3);
    d_flipflop reg_bit3(
        .clk(clk),
        .rst(rst),
        .entrada(next_q3),
        .saida_q(q[3]),
        .saida_q_invertido(q_inv_unused3)
    );

    // Bit 4
    wire rst_val4, set_val4, cen_val4, hold_val4, next_q4, q_inv_unused4;
    and(rst_val4, rst, 1'b0);
    and(set_val4, set, 1'b1);
    and(cen_val4, cen, d[4]);
    and(hold_val4, rst_n, set_n, cen_n, q[4]);
    or(next_q4, rst_val4, set_val4, cen_val4, hold_val4);
    d_flipflop reg_bit4(
        .clk(clk),
        .rst(rst),
        .entrada(next_q4),
        .saida_q(q[4]),
        .saida_q_invertido(q_inv_unused4)
    );

    // Bit 5
    wire rst_val5, set_val5, cen_val5, hold_val5, next_q5, q_inv_unused5;
    and(rst_val5, rst, 1'b0);
    and(set_val5, set, 1'b1);
    and(cen_val5, cen, d[5]);
    and(hold_val5, rst_n, set_n, cen_n, q[5]);
    or(next_q5, rst_val5, set_val5, cen_val5, hold_val5);
    d_flipflop reg_bit5(
        .clk(clk),
        .rst(rst),
        .entrada(next_q5),
        .saida_q(q[5]),
        .saida_q_invertido(q_inv_unused5)
    );

    // Bit 6
    wire rst_val6, set_val6, cen_val6, hold_val6, next_q6, q_inv_unused6;
    and(rst_val6, rst, 1'b0);
    and(set_val6, set, 1'b1);
    and(cen_val6, cen, d[6]);
    and(hold_val6, rst_n, set_n, cen_n, q[6]);
    or(next_q6, rst_val6, set_val6, cen_val6, hold_val6);
    d_flipflop reg_bit6(
        .clk(clk),
        .rst(rst),
        .entrada(next_q6),
        .saida_q(q[6]),
        .saida_q_invertido(q_inv_unused6)
    );

    // Bit 7
    wire rst_val7, set_val7, cen_val7, hold_val7, next_q7, q_inv_unused7;
    and(rst_val7, rst, 1'b0);
    and(set_val7, set, 1'b1);
    and(cen_val7, cen, d[7]);
    and(hold_val7, rst_n, set_n, cen_n, q[7]);
    or(next_q7, rst_val7, set_val7, cen_val7, hold_val7);
    d_flipflop reg_bit7(
        .clk(clk),
        .rst(rst),
        .entrada(next_q7),
        .saida_q(q[7]),
        .saida_q_invertido(q_inv_unused7)
    );
endmodule

/*
    Latch é um circuito sequencial capaz de armazenar um bit de informação.
    O latch mestre é sensível ao nível do clock (clk=0), enquanto o latch escravo é sensível ao nível oposto (clk=1).
    Juntos, eles formam o flip-flop mestre-escravo, que só altera o valor armazenado na transição do clock.
    O reset síncrono força o valor armazenado para zero quando ativado.

    No contexto do flip-flop D:
    - 'entrada' é o dado de entrada (D).
    - 'saida_q' é o valor armazenado (Q).
    - 'saida_q_invertido' é o valor invertido (Q̅).
    - O flip-flop D é o mais usado em registradores e máquinas de estados porque só atualiza Q na borda do clock,
      garantindo sincronismo e previsibilidade no circuito digital.
*/

/*
    Flip-flop D em nível de portas (baseado em NAND)
    - Latch mestre: segue a entrada enquanto clk=0 (está aberto)
    - Latch escravo: segue a entrada enquanto clk=1 (está aberto)
    - Reset síncrono: entrada_resetada = entrada & ~rst
*/
module d_flipflop(
    input clk,
    input rst,
    input entrada,
    output saida_q,
    output saida_q_invertido
);
    wire clk_n;
    not(clk_n, clk);

    // Reset assíncrono: saída vai para zero imediatamente quando rst=1
    // Reset síncrono (comentado): só zera na borda do clock
    // wire rst_n, entrada_resetada;
    // not(rst_n, rst);
    // and(entrada_resetada, entrada, rst_n);

    wire entrada_resetada;
    assign entrada_resetada = rst ? 1'b0 : entrada;

    // Latch mestre (baseado em NAND, segue a entrada enquanto clk=0)
    wire m1, m2;
    nand(m1, entrada_resetada, clk_n);
    nand(m2, m1, clk_n);

    // Latch escravo (baseado em NAND, segue a entrada enquanto clk=1)
    wire s1, s2;
    nand(s1, m2, clk);
    nand(s2, s1, clk);

    assign saida_q = s2;
    not(saida_q_invertido, s2);
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
        .cen(enable)
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
        .soma(soma),
        .carry_out(dummy_carry) // Conectado a dummy para evitar warning
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
    
    //vetor concatenado para dar tabelas iguais aos slides
    assign entradas_cc[4] = inst_temp[1]; // Corrigido para evitar erro de sintaxe
    assign entradas_cc[3] = inst_temp[0]; // Corrigido para evitar erro de sintaxe
    assign entradas_cc[2] = EA[2]; // Corrigido para evitar erro de sintaxe
    assign entradas_cc[1] = EA[1]; // Corrigido para evitar erro de sintaxe
    assign entradas_cc[0] = EA[0]; // Corrigido para evitar erro de sintaxe
    assign oEA=EA;
	 
    // Descrição do CCPE, trocar por uma chamada de CCPE com portas lógicas
    ccpe circuito_ccpe(.PE(PE), .entradas(entradas_cc));    

    // Descrição das saidas Mealy, trocar por uma chamada de CC_Saida_Mealy com portas lógicas
    saida_mealy circuito_enPC(.enPC(enPC), .entradas_cc(entradas_cc));
        
    //descrição do CCSaida_moore, trocar por uma chamada de CC_Saida_Moore com portas lógicas
    wire [5:0] saidas;	
    saidas_moore cc_saidas_moore(.EA(EA), .saidas_moore(saidas));
    
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


module reg3(clk, rst, EA, PE);
    input clk;
    input rst;
    input [2:0] PE;
    output [2:0] EA;

    // Garantia: EA sempre inicia em 000 após reset
    // Reset síncrono força todos os bits para zero
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
    // Decodificação dos estados
    wire ea0, ea1, ea2;
    wire n_ea0, n_ea1, n_ea2; // Adicionado para evitar warnings
    buf(ea0, EA[0]);
    buf(ea1, EA[1]);
    buf(ea2, EA[2]);

    // Estados da FSM:
    // estado_000: Estado inicial (fetch/opcode) — busca a instrução na memória
    // estado_001: Estado de leitura do imediato/endereço — prepara para executar STA, LDA, ADD
    // estado_010: Estado de execução LDA — carrega o acumulador com o valor da memória
    // estado_011: Estado de execução ADD — soma o valor da memória ao acumulador
    // estado_100: Estado de execução STA — armazena o valor do acumulador na memória

    // Estado 000
    wire estado_000;
    not(n_ea0, ea0);
    not(n_ea1, ea1);
    not(n_ea2, ea2);
    and(estado_000, n_ea2, n_ea1, n_ea0);

    // Estado 001
    wire estado_001;
    and(estado_001, n_ea2, n_ea1, ea0);

    // Estado 010
    wire estado_010;
    and(estado_010, n_ea2, ea1, n_ea0);

    // Estado 011
    wire estado_011;
    and(estado_011, n_ea2, ea1, ea0);

    // Estado 100
    wire estado_100;
    and(estado_100, ea2, n_ea1, n_ea0);

    // selPC: estados 000, 001
    // Nos estados 000 (fetch/opcode) e 001 (leitura do imediato/endereço), o Program Counter é selecionado para buscar instrução/endereço.
    or(saidas_moore[5], estado_000, estado_001);

    // selMEM: estados 000, 001
    // Nos estados 000 e 001, a memória é selecionada para leitura da instrução ou do dado/endereço.
    or(saidas_moore[4], estado_000, estado_001);

    // enREM: estados 000, 001
    // Nos estados 000 e 001, o registrador de endereço de memória é habilitado para armazenar o endereço corrente.
    or(saidas_moore[3], estado_000, estado_001);

    // write: estado 100
    // No estado 100 (STA), habilita escrita na memória (mem <- acc).
    buf(saidas_moore[2], estado_100);

    // opULA: estados 011
    // No estado 011 (ADD), seleciona operação de soma na ULA.
    buf(saidas_moore[1], estado_011);

    // enAC: estados 010, 011
    // Nos estados 010 (LDA) e 011 (ADD), habilita escrita no acumulador.
    or(saidas_moore[0], estado_010, estado_011);
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

module ccpe(PE, entradas);
    input [4:0] entradas;   // entradas de controle: [4:3] opcode, [2:0] EA
    output [2:0] PE;        // próximo estado (PE)
    // Conecta entradas aos fios internos
    wire ea0, ea1, ea2, opcode_lsb, opcode_msb;
    buf(ea0, entradas[0]);
    buf(ea1, entradas[1]);
    buf(ea2, entradas[2]);
    buf(opcode_lsb, entradas[3]);
    buf(opcode_msb, entradas[4]);
    wire n_ea0, n_ea1, n_ea2;
    wire n_opcode_msb, n_opcode_lsb;
    wire opcode_hlt, opcode_sta, opcode_lda, opcode_add;
    not(n_ea0, ea0);
    not(n_ea1, ea1);
    not(n_ea2, ea2);
    not(n_opcode_msb, opcode_msb);
    not(n_opcode_lsb, opcode_lsb);
    // Detecta opcode
    and(opcode_hlt, n_opcode_msb, n_opcode_lsb); // HLT: 00
    and(opcode_sta, n_opcode_msb, opcode_lsb);   // STA: 01
    and(opcode_lda, opcode_msb, n_opcode_lsb);   // LDA: 10
    and(opcode_add, opcode_msb, opcode_lsb);     // ADD: 11
    // Estados
    wire estado_000, estado_001, estado_010, estado_011, estado_100;
    and(estado_000, n_ea2, n_ea1, n_ea0);
    and(estado_001, n_ea2, n_ea1, ea0);
    and(estado_010, n_ea2, ea1, n_ea0);
    and(estado_011, n_ea2, ea1, ea0);
    and(estado_100, ea2, n_ea1, n_ea0);
    // Próximo estado para cada transição
    // Calcula cada bit do próximo estado usando apenas uma atribuição por bit
    wire pe2_sta, pe2_volta, pe2_hlt;
    wire pe1_lda, pe1_add, pe1_volta, pe1_hlt;
    wire pe0_add, pe0_next, pe0_volta, pe0_hlt;
    // PE[2]: STA (100) ou volta (010/011/100) ou HLT (000)
    and(pe2_sta, estado_001, opcode_sta); // 001->100
    or(pe2_volta, estado_010, estado_011, estado_100); // 010/011/100->000
    and(pe2_hlt, estado_000, opcode_hlt); // 000->000 (HLT)
    or(PE[2], pe2_sta, pe2_volta, pe2_hlt);
    // PE[1]: LDA (010), ADD (011), volta, ou HLT
    and(pe1_lda, estado_001, opcode_lda); // 001->010
    and(pe1_add, estado_001, opcode_add); // 001->011
    or(pe1_volta, estado_010, estado_011, estado_100); // 010/011/100->000
    and(pe1_hlt, estado_000, opcode_hlt); // 000->000 (HLT)
    or(PE[1], pe1_lda, pe1_add, pe1_volta, pe1_hlt);
    // PE[0]: ADD (011), next (001), volta, ou HLT
    and(pe0_add, estado_001, opcode_add); // 001->011
    and(pe0_next, estado_000, ~opcode_hlt); // 000->001 (não HLT)
    or(pe0_volta, estado_010, estado_011, estado_100); // 010/011/100->000
    and(pe0_hlt, estado_000, opcode_hlt); // 000->000 (HLT)
    or(PE[0], pe0_add, pe0_next, pe0_volta, pe0_hlt);
    /*
        Cada bit de PE é calculado por uma única expressão combinacional,
        evitando múltiplos drivers e loops lógicos. Comentários detalham
        cada transição de estado para fins educacionais.
    */
endmodule

/****************************************************************************** 
(c) 2023, 2024, 2025 Andre Reis - UFRGS - InPlace 
Module name : trad_inst_pit
Description : This module translates instruction codes from 4-bits to 2-bits
              and stores the translated codes for the extra cycles needed to 
              complete the instructions. The translation is combinational,
              the storing of the translated codes is sequential.
******************************************************************************/
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

/****************************************************************************** 
Somador de 8 bits usando half_adders em cascata
Description : Soma dois números de 8 bits usando uma cadeia de half_adder
******************************************************************************/
/*
    O módulo somador_8b realiza a soma de dois números de 8 bits.
    Utiliza uma cadeia de half_adder para propagar o carry entre os bits.
    O resultado é a soma e o carry_out indica overflow.
*/
module somador_8b(
    input [7:0] a,                // Primeiro operando de 8 bits
    input [7:0] b,                // Segundo operando de 8 bits
    output [7:0] soma,            // Resultado da soma
    output carry_out              // Carry de saída (overflow)
);

    // Fios internos para conectar os carries entre os bits
    wire carry0, carry1, carry2, carry3, carry4, carry5, carry6;

    // Bit 0 (LSB)
    half_adder half_adder_bit0(
        .a(a[0]),
        .b(b[0]),
        .sum(soma[0]),
        .carry(carry0)
    );

    // Bit 1
    half_adder half_adder_bit1(
        .a(a[1]),
        .b(carry0),
        .sum(soma[1]),
        .carry(carry1)
    );

    // Bit 2
    half_adder half_adder_bit2(
        .a(a[2]),
        .b(carry1),
        .sum(soma[2]),
        .carry(carry2)
    );

    // Bit 3
    half_adder half_adder_bit3(
        .a(a[3]),
        .b(carry2),
        .sum(soma[3]),
        .carry(carry3)
    );

    // Bit 4
    half_adder half_adder_bit4(
        .a(a[4]),
        .b(carry3),
        .sum(soma[4]),
        .carry(carry4)
    );

    // Bit 5
    half_adder half_adder_bit5(
        .a(a[5]),
        .b(carry4),
        .sum(soma[5]),
        .carry(carry5)
    );

    // Bit 6
    half_adder half_adder_bit6(
        .a(a[6]),
        .b(carry5),
        .sum(soma[6]),
        .carry(carry6)
    );

    // Bit 7 (MSB)
    half_adder half_adder_bit7(
        .a(a[7]),
        .b(carry6),
        .sum(soma[7]),
        .carry(carry_out)
    );

endmodule

/****************************************************************************** 
Half-adder implementation using basic logic gates
Inputs: a, b (single bits)
Outputs: sum, carry
******************************************************************************/

/*
    O módulo half_adder implementa um somador de meio bit (half-adder).
    Ele soma dois bits de entrada e gera um bit de soma e um bit de carry.
    Soma = a XOR b, Carry = a AND b.
*/

module half_adder(
    input a,        // Primeiro bit de entrada
    input b,        // Segundo bit de entrada
    output sum,     // Bit de soma (a XOR b)
    output carry    // Bit de carry (a AND b)
);
    // Soma = a XOR b
    xor(sum, a, b);
    
    // Carry = a AND b
    and(carry, a, b);
endmodule