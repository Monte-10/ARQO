--------------------------------------------------------------------------------
-- Procesador RISC V uniciclo curso Arquitectura Ordenadores 2022
-- Initial Release G.Sutter jun 2022
-- Team Members: Ana Stonek, Lía Castañeda
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.RISCV_pack.all;

entity processorRV is
   port(
      Clk      : in  std_logic;                     -- Reloj activo en flanco subida
      Reset    : in  std_logic;                     -- Reset asincrono activo nivel alto
      -- Instruction memory
      IDataIn  : in  std_logic_vector(31 downto 0); -- Instruccion leida
      IAddr    : out std_logic_vector(31 downto 0); -- Direccion Instr
      -- Data memory
      DAddr    : out std_logic_vector(31 downto 0); -- Direccion
      DRdEn    : out std_logic;                     -- Habilitacion lectura
      DWrEn    : out std_logic;                     -- Habilitacion escritura
      DDataOut : out std_logic_vector(31 downto 0); -- Dato escrito
      DDataIn  : in  std_logic_vector(31 downto 0)  -- Dato leido
   );
end processorRV;

architecture rtl of processorRV is

  component alu_RV
    port (
      OpA     : in  std_logic_vector (31 downto 0); -- Operando A
      OpB     : in  std_logic_vector (31 downto 0); -- Operando B
      Control : in  std_logic_vector ( 3 downto 0); -- Codigo de control=op. a ejecutar
      Result  : out std_logic_vector (31 downto 0); -- Resultado
      SignFlag: out std_logic;                      -- Sign Flag
      carryOut: out std_logic;                      -- Carry bit
      ZFlag   : out std_logic                       -- Flag Z
    );
  end component;

  component reg_bank
     port (
        Clk   : in  std_logic;                      -- Reloj activo en flanco de subida
        Reset : in  std_logic;                      -- Reset as?ncrono a nivel alto
        A1    : in  std_logic_vector(4 downto 0);   -- Direcci?n para el puerto Rd1
        Rd1   : out std_logic_vector(31 downto 0);  -- Dato del puerto Rd1
        A2    : in  std_logic_vector(4 downto 0);   -- Direcci?n para el puerto Rd2
        Rd2   : out std_logic_vector(31 downto 0);  -- Dato del puerto Rd2
        A3    : in  std_logic_vector(4 downto 0);   -- Direcci?n para el puerto Wd3
        Wd3   : in  std_logic_vector(31 downto 0);  -- Dato de entrada Wd3
        We3   : in  std_logic                       -- Habilitaci?n de la escritura de Wd3
     ); 
  end component reg_bank;

  component control_unit
     port (
        -- Entrada = codigo de operacion en la instruccion:
        OpCode   : in  std_logic_vector (6 downto 0);
        -- Seniales para el PC
        Branch   : out  std_logic;                     -- 1 = Ejecutandose instruccion branch
        -- Seniales relativas a la memoria
        ResultSrc: out  std_logic_vector(1 downto 0);  -- 00 salida Alu; 01 = salida de la mem.; 10 PC_plus4
        MemWrite : out  std_logic;                     -- Escribir la memoria
        MemRead  : out  std_logic;                     -- Leer la memoria
        -- Seniales para la ALU
        ALUSrc   : out  std_logic;                     -- 0 = oper.B es registro, 1 = es valor inm.
        AuipcLui : out  std_logic_vector (1 downto 0); -- 0 = PC. 1 = zeros, 2 = reg1.
        ALUOp    : out  std_logic_vector (2 downto 0); -- Tipo operacion para control de la ALU
        -- señal generacion salto
        Ins_jalr  : out  std_logic;                    -- 0=any instrucion, 1=jalr
        -- Seniales para el GPR
        RegWrite : out  std_logic                      -- 1 = Escribir registro
     );
  end component;

  component alu_control is
    port (
      -- Entradas:
      ALUOp  : in std_logic_vector (2 downto 0);     -- Codigo de control desde la unidad de control
      Funct3 : in std_logic_vector (2 downto 0);     -- Campo "funct3" de la instruccion (I(14:12))
      Funct7 : in std_logic_vector (6 downto 0);     -- Campo "funct7" de la instruccion (I(31:25))     
      -- Salida de control para la ALU:
      ALUControl : out std_logic_vector (3 downto 0) -- Define operacion a ejecutar por la ALU
    );
  end component alu_control;

 component Imm_Gen is
    port (
        instr     : in std_logic_vector(31 downto 0);
        imm       : out std_logic_vector(31 downto 0)
    );
  end component Imm_Gen;

  -------SIGNALS---------------------------------------------------------

  signal Alu_Op1_EX      : std_logic_vector(31 downto 0);
  signal Alu_Op2_EX      : std_logic_vector(31 downto 0);
  signal Alu_ZERO_EX     : std_logic;
  signal Alu_SIGN_EX      : std_logic;
  signal AluControl_EX   : std_logic_vector(3 downto 0);
  signal reg_RD_data_WB  : std_logic_vector(31 downto 0);

  signal branch_true_MEM : std_logic;
  signal PC_next        : std_logic_vector(31 downto 0);
  signal PC_reg         : std_logic_vector(31 downto 0);
  signal PC_plus4       : std_logic_vector(31 downto 0);

  signal Inm_ext_ID        : std_logic_vector(31 downto 0); -- La parte baja de la instrucción extendida de signo
  signal reg_RS_ID, reg_RT_ID : std_logic_vector(31 downto 0);

  signal dataIn_MEM     : std_logic_vector(31 downto 0); -- From Data Memory
  signal Addr_Branch_EX    : std_logic_vector(31 downto 0);

  signal Ctrl_Jalr, Ctrl_Branch, Ctrl_MemWrite, Ctrl_MemRead,  Ctrl_ALUSrc, Ctrl_RegWrite : std_logic;
  
  --Ctrl_RegDest,
  signal Ctrl_ALUOP     : std_logic_vector(2 downto 0);
  signal Ctrl_PcLui     : std_logic_vector(1 downto 0);
  signal Ctrl_ResSrc    : std_logic_vector(1 downto 0);

  signal Addr_jalr_EX      : std_logic_vector(31 downto 0);
  signal Addr_Jump_dest_EX : std_logic_vector(31 downto 0);
  signal desition_Jump_MEM  : std_logic;
  signal Alu_Res_EX        : std_logic_vector(31 downto 0);
  -- Instruction filds
  signal Funct3_ID         : std_logic_vector(2 downto 0);
  signal Funct7_ID         : std_logic_vector(6 downto 0);
  signal RS1_ID, RS2_ID, RD_ID   : std_logic_vector(4 downto 0);


  --IF/ID
  signal PC_ID : std_logic_vector(31 downto 0);
  signal instruction_ID : std_logic_vector(31 downto 0);
  signal PC_IF : std_logic_vector(31 downto 0);
  signal instruccion_IF : std_logic_vector(31 downto 0);
  signal enable_IF_ID : std_logic;

  --ID/EX
  signal Funct3_EX : std_logic_vector(2 downto 0);
  signal Funct7_EX : std_logic_vector(6 downto 0);
  signal PC_EX : std_logic_vector(31 downto 0);
  signal Ctrl_ResSrc_EX: std_logic_vector(1 downto 0);
  signal Ctrl_jalr_EX, Ctrl_Branch_EX, Ctrl_MemWrite_EX, Ctrl_MemRead_EX,  Ctrl_ALUSrc_EX, Ctrl_RegWrite_EX: std_logic;
  signal Ctrl_PcLui_EX: std_logic_vector(1 downto 0);
  signal Ctrl_ALUOP_EX: std_logic_vector(2 downto 0);
  signal enable_ID_EX: std_logic;
  signal Inm_ext_EX : std_logic_vector(31 downto 0);
  signal RD_EX   : std_logic_vector(4 downto 0);
  signal reg_RS_EX, reg_RT_EX : std_logic_vector(31 downto 0);

  --EX/MEM
  signal Addr_Jump_dest_MEM : std_logic_vector(31 downto 0);
  signal Ctrl_jalr_MEM, Ctrl_Branch_MEM, Ctrl_MemWrite_MEM, Ctrl_MemRead_MEM, Ctrl_RegWrite_MEM: std_logic;
  signal Funct3_MEM : std_logic_vector(2 downto 0);
  signal RD_MEM   : std_logic_vector(4 downto 0);
  signal reg_RT_MEM : std_logic_vector(31 downto 0);
  signal  Alu_Res_MEM        : std_logic_vector(31 downto 0);
  signal Alu_ZERO_MEM    : std_logic;
  signal Alu_SIGN_MEM      : std_logic;
  signal enable_EX_MEM: std_logic;
  signal Ctrl_ResSrc_MEM: std_logic_vector(1 downto 0);

  --MEM/WB
  signal RD_WB   : std_logic_vector(4 downto 0);
  signal Ctrl_RegWrite_WB: std_logic;
  signal Ctrl_ResSrc_WB: std_logic_vector(1 downto 0);
  signal  Alu_Res_WB        : std_logic_vector(31 downto 0);
  signal dataIn_WB     : std_logic_vector(31 downto 0); -- From Data Memory
  signal enable_MEM_WB: std_logic;

  --Forwarding Unit
  signal Rs1_EX: std_logic_vector(4 downto 0);
  signal Rs2_EX: std_logic_vector(4 downto 0);
  signal ForwardA: std_logic_vector(1 downto 0);
  signal ForwardB: std_logic_vector(1 downto 0);
  signal auxsigalOP2: std_logic_vector(31 downto 0);
  signal auxsigalOP1: std_logic_vector(31 downto 0);

  --hazard detection unit 
  signal Ctrl_mux_hazard: std_logic;

  signal Ctrl_Branch_MUX : std_logic;
  signal Ctrl_ResSrc_MUX : std_logic_vector(1 downto 0);
  signal Ctrl_MemWrite_MUX: std_logic; 
  signal Ctrl_MemRead_MUX: std_logic;
  signal Ctrl_PcLui_MUX: std_logic_vector(1 downto 0);
  signal Ctrl_jalr_MUX: std_logic; 
  signal Ctrl_RegWrite_MUX: std_logic;

  signal Ctrl_ALUSrc_MUX: std_logic;
  signal Ctrl_ALUOP_MUX :  std_logic_vector(2 downto 0);
  signal flush_IF_ID, flush_ID_EX, flush_EX_MEM: std_logic;


begin

  ---Program Counter---------
  PC_reg_proc: process(Clk, Reset)
  begin
    if Reset = '1' then
      PC_reg <= (22 => '1', others => '0'); -- pone direccion inicial de instrucciones en 0040_0000
    elsif rising_edge(Clk) then
      PC_reg <= PC_next;
    end if;
  end process;

  -------IF/ID-----------------------------

    IF_ID_Regs: process(clk,reset)
    begin
      if Reset = '1' then
        PC_ID <= (others=>'0');
        instruction_ID <=(others=>'0');
      elsif rising_edge(clk) then
        if enable_IF_ID = '1' and flush_IF_ID = '0' then 
          PC_ID<=PC_IF;
          instruction_ID<=instruccion_IF;

        elsif flush_IF_ID = '1' then --Flush instruction
          PC_ID <= (others=>'0');
          instruction_ID <=(others=>'0');
        end if;

      end if;
    end process;

    enable_IF_ID<='1';
    IAddr<=PC_IF;
    PC_IF<= PC_reg; 
    instruccion_IF <= IDataIn;

    PC_plus4    <= PC_reg + 4;

    Funct3_ID      <= instruction_ID(14 downto 12); -- Campo "funct3" de la instruccion
    Funct7_ID      <= instruction_ID(31 downto 25); -- Campo "funct7" de la instruccion
    RD_ID          <= instruction_ID(11 downto 7);
    RS1_ID         <= instruction_ID(19 downto 15);
    RS2_ID        <= instruction_ID(24 downto 20);

  -----HAZARD DETECTION UNIT-----------------
    
    --Stall: 1 Continue: 0
    Ctrl_mux_hazard <= '1' when ((Ctrl_MemRead_EX = '1') and ((RD_EX = RS1_ID) or (RD_EX = RS2_ID))) else '0';
    
    Ctrl_Branch_MUX <= Ctrl_Branch when Ctrl_mux_hazard = '0' else '0';
    Ctrl_ResSrc_MUX <= Ctrl_ResSrc when Ctrl_mux_hazard = '0' else (others => '0');
    Ctrl_MemWrite_MUX <= Ctrl_MemWrite when Ctrl_mux_hazard = '0' else '0';
    Ctrl_MemRead_MUX <= Ctrl_MemRead when Ctrl_mux_hazard = '0' else '0';
    Ctrl_PcLui_MUX <= Ctrl_PcLui when Ctrl_mux_hazard = '0' else (others => '0');
    Ctrl_jalr_MUX <= Ctrl_jalr when Ctrl_mux_hazard = '0' else '0'; -- TODO : OJO : Ctrl_jalr No está definido pero no da error
    Ctrl_RegWrite_MUX <= Ctrl_RegWrite when Ctrl_mux_hazard = '0' else '0';
    Ctrl_ALUSrc_MUX <= Ctrl_ALUSrc when Ctrl_mux_hazard = '0' else '0';
    Ctrl_ALUOP_MUX <= Ctrl_ALUOP when Ctrl_mux_hazard = '0' else (others => '0');

    --Disable IF/ID pipeline if Stalling 
    enable_IF_ID <= '0' when (Ctrl_mux_hazard = '1') else '1';

    --Avoid PC update if stalling
    PC_next <= Addr_Jump_dest_MEM when (desition_Jump_MEM = '1') else 
              PC_reg when (Ctrl_mux_hazard = '1') else
              PC_plus4;
    
  ------ID/EX--------------------------------
   
    ID_EX_Regs: process(clk,reset)
    begin
      if Reset = '1' then
        PC_EX<=(others=>'0');
        Funct3_EX<=(others=>'0');
        Funct7_EX<=(others=>'0');
        Inm_ext_EX<=(others => '0');
        RD_EX<=(others => '0');

        Ctrl_Branch_EX<= '0';
        Ctrl_ResSrc_EX <= (others => '0');
        Ctrl_MemWrite_EX<='0';
        Ctrl_MemRead_EX<='0';
        Ctrl_PcLui_EX<=(others => '0');
        Ctrl_jalr_EX<='0'; 
        Ctrl_RegWrite_EX<='0';

        reg_RS_EX <= (others => '0');
        reg_RT_EX <= (others => '0');

        Ctrl_ALUSrc_EX<='0';
        Ctrl_ALUOP_EX<=(others => '0');

        rs1_EX <= (others => '0');
        rs2_EX <=(others => '0');

      elsif rising_edge(clk) then 
        if enable_ID_EX='1' and flush_ID_EX = '0' then
          PC_EX<=PC_ID;
          Funct3_EX<= Funct3_ID;  
          Funct7_EX<= Funct7_ID;
          Inm_ext_EX<=Inm_ext_ID;
          RD_EX <= RD_ID;

          rs1_EX <= RS1_ID;
          rs2_EX <= RS2_ID;

          Ctrl_Branch_EX <= Ctrl_Branch_MUX; 
          Ctrl_ResSrc_EX <= Ctrl_ResSrc_MUX;
          Ctrl_MemWrite_EX<=Ctrl_MemWrite_MUX; 
          Ctrl_MemRead_EX<=Ctrl_MemRead_MUX;
          Ctrl_PcLui_EX<=Ctrl_PcLui_MUX;
          Ctrl_jalr_EX<=Ctrl_jalr_MUX; 
          Ctrl_RegWrite_EX<=Ctrl_RegWrite_MUX;

          reg_RS_EX <= reg_RS_ID;
          reg_RT_EX <= reg_RT_ID;

          Ctrl_ALUSrc_EX<=Ctrl_ALUSrc_MUX;
          Ctrl_ALUOP_EX<=Ctrl_ALUOP_MUX;

        elsif flush_ID_EX = '1' then --flush instruction
          PC_EX<=(others=>'0');
          Funct3_EX<=(others=>'0');
          Funct7_EX<=(others=>'0');
          Inm_ext_EX<=(others => '0');
          RD_EX<=(others => '0');

          Ctrl_Branch_EX<= '0';
          Ctrl_ResSrc_EX <= (others => '0');
          Ctrl_MemWrite_EX<='0';
          Ctrl_MemRead_EX<='0';
          Ctrl_PcLui_EX<=(others => '0');
          Ctrl_jalr_EX<='0'; 
          Ctrl_RegWrite_EX<='0';

          reg_RS_EX <= (others => '0');
          reg_RT_EX <= (others => '0');

          Ctrl_ALUSrc_EX<='0';
          Ctrl_ALUOP_EX<=(others => '0');

          rs1_EX <= (others => '0');
          rs2_EX <=(others => '0');
        end if;
          
      end if;
    end process;

    enable_ID_EX<='1';

    Addr_Branch_EX    <= PC_EX + Inm_ext_EX;
    Addr_jalr_EX    <= reg_RS_EX + Inm_ext_EX;

    Addr_Jump_dest_EX <= Addr_jalr_EX   when Ctrl_jalr_EX = '1' else
    Addr_Branch_EX when Ctrl_Branch_EX='1' else
    (others =>'0');

    --MUX OP1 ALU inputs
    auxsigalOP1    <= PC_EX  when Ctrl_PcLui_EX = "00" else
                  (others => '0')  when Ctrl_PcLui_EX = "01" else
                  reg_RS_EX; -- --No forwarding input 
    
    Alu_Op1_EX <= Alu_Res_MEM when ForwardA = "10" and not (Ctrl_PcLui_EX = "00" or Ctrl_PcLui_EX = "01" ) else
                  reg_RD_data_WB when ForwardA = "01" and not (Ctrl_PcLui_EX = "00" or Ctrl_PcLui_EX = "01" ) else
                  auxsigalOP1;

    --MUX OP2 ALU INPUT
    auxsigalOP2   <= reg_RT_EX when Ctrl_ALUSrc_EX = '0' else Inm_ext_EX; --No forwarding input 
    
    Alu_Op2_EX <= Alu_Res_MEM when (ForwardB = "10") and (Ctrl_ALUSrc_EX = '0') else
                  reg_RD_data_WB when (ForwardB = "01") and  (Ctrl_ALUSrc_EX = '0') else
                  auxsigalOP2;
    
    -----Forwarding Unit--------------------------
    
    ForwardA <= "10" when ((Ctrl_RegWrite_MEM = '1')  and (RD_MEM /=  "00000")  and (RD_MEM = Rs1_EX )) or
    ((Ctrl_Branch_EX = '1') and (RD_MEM = Rs1_EX )  and (RD_MEM /=  "00000") and (Ctrl_RegWrite_MEM = '1'))  else 
    "01" when ((Ctrl_RegWrite_WB = '1' ) and (RD_WB /=  "00000")  and (RD_WB = Rs1_EX) and not ((Ctrl_RegWrite_MEM = '1') and (RD_MEM /=  "00000") and (RD_MEM =  Rs1_EX))) or
    
    ((Ctrl_Branch_EX = '1' ) and (RD_WB /=  "00000")  and (RD_WB = Rs1_EX) and (Ctrl_RegWrite_WB = '1' )) else --Branch forwarding
    "00"; --normal input "00"

    ForwardB <= "10" when ((Ctrl_RegWrite_MEM = '1') and (RD_MEM /=  "00000")  and (RD_MEM = Rs2_EX)) or
    ((Ctrl_Branch_EX = '1') and (RD_MEM = Rs2_EX ) and (RD_MEM /=  "00000") and (Ctrl_RegWrite_MEM = '1'))  else
    "01" when ( (Ctrl_RegWrite_WB  = '1') and (RD_WB /=  "00000")  and (RD_WB = Rs2_EX) and not ((Ctrl_RegWrite_MEM = '1') and (RD_MEM /=  "00000") and (RD_MEM = Rs2_EX))) or 
    
    ((Ctrl_Branch_EX = '1' ) and (RD_WB /=  "00000")  and (RD_WB = Rs2_EX) and (Ctrl_RegWrite_WB  = '1')) else --Branch forwarding
    "00"; --normal input  "00"

  ------EX/MEM-----------------------------------

  EX_MEM_Regs: process(clk,reset)
  begin
    if Reset = '1' then
      Addr_Jump_dest_MEM <= (others => '0');
      Ctrl_Jalr_MEM<='0';
      Ctrl_Branch_MEM<='0';

      Alu_ZERO_MEM<= '0';
      Alu_SIGN_MEM<='0';

      Funct3_MEM<=(others => '0');

      Ctrl_MemWrite_MEM<= '0';
      Ctrl_MemRead_MEM<='0';

      RD_MEM<=(others => '0');
      reg_RT_MEM<=(others => '0');
      Alu_Res_MEM<=(others => '0');

      Ctrl_ResSrc_MEM<= (others => '0');
      Ctrl_RegWrite_MEM<='0';
      
    elsif rising_edge(clk)  then 
      if enable_EX_MEM='1' and flush_EX_MEM = '0' then
        Addr_Jump_dest_MEM <= Addr_Jump_dest_EX;
        Ctrl_Jalr_MEM<=Ctrl_jalr_EX;
        Ctrl_Branch_MEM<=Ctrl_Branch_EX;

        Alu_ZERO_MEM<= Alu_ZERO_EX;
        Alu_SIGN_MEM<=Alu_SIGN_EX;

        Funct3_MEM<=Funct3_EX;

        Ctrl_MemWrite_MEM<= Ctrl_MemWrite_EX;
        Ctrl_MemRead_MEM<=Ctrl_MemRead_EX;

        RD_MEM<=RD_EX;
        reg_RT_MEM<=reg_RT_EX;
        Alu_Res_MEM<=Alu_Res_EX;

        Ctrl_ResSrc_MEM<= Ctrl_ResSrc_EX;
        Ctrl_RegWrite_MEM<=Ctrl_RegWrite_EX;

      elsif flush_EX_MEM = '1' then   --Flush instruction
        Addr_Jump_dest_MEM <= (others => '0');
        Ctrl_Jalr_MEM<='0';
        Ctrl_Branch_MEM<='0';

        Alu_ZERO_MEM<= '0';
        Alu_SIGN_MEM<='0';

        Funct3_MEM<=(others => '0');

        Ctrl_MemWrite_MEM<= '0';
        Ctrl_MemRead_MEM<='0';

        RD_MEM<=(others => '0');
        reg_RT_MEM<=(others => '0');
        Alu_Res_MEM<=(others => '0');

        Ctrl_ResSrc_MEM<= (others => '0');
        Ctrl_RegWrite_MEM<='0';
      end if;
    end if;
  end process;

  enable_EX_MEM<='1';

  desition_Jump_MEM  <= Ctrl_Jalr_MEM or (Ctrl_Branch_MEM and branch_true_MEM);

  branch_true_MEM    <= '1' when ( ((Funct3_MEM = BR_F3_BEQ) and (Alu_ZERO_MEM = '1')) or
  ((Funct3_MEM = BR_F3_BNE) and (Alu_ZERO_MEM = '0')) or
  ((Funct3_MEM = BR_F3_BLT) and (Alu_SIGN_MEM = '1')) or
  ((Funct3_MEM = BR_F3_BGT) and (Alu_SIGN_MEM = '0')) ) else '0';

  DWrEn<= Ctrl_MemWrite_MEM;
  dRdEn<= Ctrl_MemRead_MEM;
  DDataOut<= reg_RT_MEM;
  DAddr<= Alu_Res_MEM;
  dataIn_MEM <= DDataIn;

  --Flush intructions in IF, ID, EX if Branch True
  flush_IF_ID <= '1' when desition_Jump_MEM = '1' else '0';
  flush_ID_EX <='1' when desition_Jump_MEM = '1' else '0';
  flush_EX_MEM <= '1' when desition_Jump_MEM = '1' else '0';

  ------MEM/WB-----------------------------------
  MEM_WB_Regs: process(clk,reset)
  begin
    if Reset = '1' then
      dataIn_WB<=(others => '0');
      Alu_Res_WB<= (others => '0');
      Ctrl_ResSrc_WB<= (others => '0');
      Ctrl_RegWrite_WB<= '0';
      RD_WB<=(others => '0');
      
    elsif rising_edge(clk) and enable_MEM_WB='1' then 
      dataIn_WB<=dataIn_MEM;
      Alu_Res_WB<= Alu_Res_MEM; 
      Ctrl_ResSrc_WB<=Ctrl_ResSrc_MEM;
      Ctrl_RegWrite_WB<=Ctrl_RegWrite_MEM;
      RD_WB<=RD_MEM;
    end if;
  end process;

  enable_MEM_WB<='1';

  --What it writes into reg bank
  reg_RD_data_WB <= dataIn_WB when Ctrl_ResSrc_WB = "01" else
                   PC_plus4   when Ctrl_ResSrc_WB = "10" else 
                   Alu_Res_WB; -- When 00

  -----PORTMAPS-------------------------------------

  RegsRISCV : reg_bank
  port map (
    Clk   => Clk,
    Reset => Reset,
    A1    => RS1_ID, --Instruction(19 downto 15), --rs1
    Rd1   => reg_RS_ID,
    A2    => RS2_ID, --Instruction(24 downto 20), --rs2
    Rd2   => reg_RT_ID,
    A3    => RD_WB, --Instruction(11 downto 7),,
    Wd3   => reg_RD_data_WB,
    We3   => Ctrl_RegWrite_WB
  );

  UnidadControl : control_unit
  --ID SIGNALS (in second stage)
  port map(
    OpCode   => instruction_ID(6 downto 0),
    -- Señales para el PC
    --Jump   => CONTROL_JUMP,
    Branch   => Ctrl_Branch,
    -- Señales para la memoria
    ResultSrc=> Ctrl_ResSrc,
    MemWrite => Ctrl_MemWrite,
    MemRead  => Ctrl_MemRead,
    -- Señales para la ALU
    ALUSrc   => Ctrl_ALUSrc,
    AuipcLui => Ctrl_PcLui,
    ALUOP    => Ctrl_ALUOP,
    -- señal generacion salto
    Ins_jalr => Ctrl_jalr, -- 0=any instrucion, 1=jalr
    -- Señales para el GPR
    RegWrite => Ctrl_RegWrite
  );

  inmed_op : Imm_Gen
  port map (
        instr    => instruction_ID,
        imm      => Inm_ext_ID
  );

  Alu_control_i: alu_control
  port map(
    -- Entradas:
    ALUOp  => Ctrl_ALUOP_EX, -- Codigo de control desde la unidad de control
    Funct3  => Funct3_EX,    -- Campo "funct3" de la instruccion
    Funct7  => Funct7_EX,    -- Campo "funct7" de la instruccion
    -- Salida de control para la ALU:
    ALUControl => AluControl_EX -- Define operacion a ejecutar por la ALU
  );

  Alu_RISCV : alu_RV
  port map (
    OpA      => Alu_Op1_EX,
    OpB      => Alu_Op2_EX,
    Control  => AluControl_EX,
    Result   => Alu_Res_EX,
    Signflag => Alu_SIGN_EX,
    carryOut => open,
    Zflag    => Alu_ZERO_EX
  );

  

end architecture;
