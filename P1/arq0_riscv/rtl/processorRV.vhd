--------------------------------------------------------------------------------
-- Procesador RISC V uniciclo curso Arquitectura Ordenadores 2023
-- Initial Release G.Sutter jun 2022. Last Rev. sep2023
-- 
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
      IAddr    : out std_logic_vector(31 downto 0); -- Direccion Instr
      IDataIn  : in  std_logic_vector(31 downto 0); -- Instruccion leida
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
      CarryOut: out std_logic;                      -- Carry bit
      ZFlag   : out std_logic                       -- Flag Z
    );
  end component;

  component reg_bank
     port (
        Clk   : in  std_logic;                      -- Reloj activo en flanco de subida
        Reset : in  std_logic;                      -- Reset asincrono a nivel alto
        A1    : in  std_logic_vector(4 downto 0);   -- Direccion para el primer registro fuente (rs1)
        Rd1   : out std_logic_vector(31 downto 0);  -- Dato del primer registro fuente (rs1)
        A2    : in  std_logic_vector(4 downto 0);   -- Direccion para el segundo registro fuente (rs2)
        Rd2   : out std_logic_vector(31 downto 0);  -- Dato del segundo registro fuente (rs2)
        A3    : in  std_logic_vector(4 downto 0);   -- Direccion para el registro destino (rd)
        Wd3   : in  std_logic_vector(31 downto 0);  -- Dato de entrada para el registro destino (rd)
        We3   : in  std_logic                       -- Habilitacion de la escritura de Wd3 (rd)
     ); 
  end component reg_bank;

  component control_unit
     port (
        -- Entrada = codigo de operacion en la instruccion:
        OpCode   : in  std_logic_vector (6 downto 0);
        -- Seniales para el PC
        Branch   : out  std_logic;                     -- 1 = Ejecutandose instruccion branch
        Ins_Jal  : out  std_logic;                     -- 1 = jal , 0 = otra instruccion, 
        Ins_Jalr : out  std_logic;                     -- 1 = jalr, 0 = otra instruccion, 
        -- Seniales relativas a la memoria y seleccion dato escritura registros
        ResultSrc: out  std_logic_vector(1 downto 0);  -- 00 salida Alu; 01 = salida de la mem.; 10 PC_plus4
        MemWrite : out  std_logic;                     -- Escribir la memoria
        MemRead  : out  std_logic;                     -- Leer la memoria
        -- Seniales para la ALU
        ALUSrc   : out  std_logic;                     -- 0 = oper.B es registro, 1 = es valor inm.
        AuipcLui : out  std_logic_vector (1 downto 0); -- 0 = PC. 1 = zeros, 2 = reg1.
        ALUOp    : out  std_logic_vector (2 downto 0); -- Tipo operacion para control de la ALU
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
  signal Alu_SIGN_EX     : std_logic;
  signal AluControl_EX   : std_logic_vector(3 downto 0);
  signal reg_RD_data_WB  : std_logic_vector(31 downto 0);

  signal branch_true_MEM : std_logic;
  signal PC_next        : std_logic_vector(31 downto 0);
  signal PC_reg         : std_logic_vector(31 downto 0);
  signal PC_plus4       : std_logic_vector(31 downto 0);

  signal Imm_ext_ID        : std_logic_vector(31 downto 0); -- La parte baja de la instrucción extendida de signo
  signal reg_RS1_ID, reg_RS2_ID : std_logic_vector(31 downto 0);

  signal dataIn_Mem     : std_logic_vector(31 downto 0); -- Dato desde memoria
  signal Addr_BranchJal_EX : std_logic_vector(31 downto 0);

  signal Ctrl_Jal, Ctrl_Jalr, Ctrl_Branch, Ctrl_MemWrite, Ctrl_MemRead,  Ctrl_ALUSrc, Ctrl_RegWrite : std_logic;
  
  signal Ctrl_ALUOp     : std_logic_vector(2 downto 0);
  signal Ctrl_PcLui     : std_logic_vector(1 downto 0);
  signal Ctrl_ResSrc    : std_logic_vector(1 downto 0);

  signal Addr_Jalr_EX      : std_logic_vector(31 downto 0);
  signal Addr_Jump_dest_EX : std_logic_vector(31 downto 0);
  signal decision_Jump_MEM  : std_logic;
  signal Alu_Res_EX        : std_logic_vector(31 downto 0);
  -- Instruction fields:
  signal Funct3_ID         : std_logic_vector(2 downto 0);
  signal Funct7_ID         : std_logic_vector(6 downto 0);
  signal RS1_ID, RS2_ID, RD_ID   : std_logic_vector(4 downto 0);

  --IF/ID
  signal PC_ID : std_logic_vector(31 downto 0);
  signal Instruction_ID : std_logic_vector(31 downto 0); -- La instrucción desde lamem de instr
  signal PC_IF : std_logic_vector(31 downto 0);
  signal Instruction_IF : std_logic_vector(31 downto 0); -- La instrucción desde lamem de instr
  signal enable_IF_ID : std_logic;

  --ID/EX
  signal Funct3_EX : std_logic_vector(2 downto 0);
  signal Funct7_EX : std_logic_vector(6 downto 0);
  signal PC_EX : std_logic_vector(31 downto 0);
  signal Ctrl_ResSrc_EX: std_logic_vector(1 downto 0);
  signal Ctrl_Jal_EX, Ctrl_Jalr_EX, Ctrl_Branch_EX, Ctrl_MemWrite_EX, Ctrl_MemRead_EX,  Ctrl_ALUSrc_EX, Ctrl_RegWrite_EX : std_logic;
  signal Ctrl_PcLui_EX: std_logic_vector(1 downto 0);
  signal Ctrl_ALUOp_EX: std_logic_vector(2 downto 0);
  signal enable_ID_EX: std_logic;
  signal Imm_ext_EX: std_logic_vector(31 downto 0);
  signal RD_EX   : std_logic_vector(4 downto 0);
  signal reg_RS1_EX, reg_RS2_EX : std_logic_vector(31 downto 0);

  --EX/MEM
  signal Addr_Jump_dest_MEM : std_logic_vector(31 downto 0);
  signal Ctrl_Jal_MEM, Ctrl_Jalr_MEM, Ctrl_Branch_MEM, Ctrl_MemWrite_MEM, Ctrl_MemRead_MEM,  Ctrl_ALUSrc_MEM, Ctrl_RegWrite_MEM : std_logic;
  signal Funct3_MEM : std_logic_vector(2 downto 0);
  signal RD_MEM   : std_logic_vector(4 downto 0);
  signal reg_RS2_MEM : std_logic_vector(31 downto 0);
  signal Alu_Res_MEM : std_logic_vector(31 downto 0);
  signal Alu_ZERO_MEM : std_logic;
  signal Alu_SIGN_MEM : std_logic;
  signal enable_EX_MEM: std_logic;
  signal Ctrl_ResSrc_MEM: std_logic_vector(1 downto 0);

  --MEM/WB
  signal RD_WB   : std_logic_vector(4 downto 0);
  signal Ctrl_RegWrite_WB: std_logic;
  signal Ctrl_ResSrc_WB: std_logic_vector(1 downto 0);
  signal Alu_Res_WB : std_logic_vector(31 downto 0);
  signal dataIn_WB : std_logic_vector(31 downto 0);
  signal enable_MEM_WB: std_logic;

begin

  -- Program Counter
  PC_reg_proc: process(Clk, Reset)
  begin
    if Reset = '1' then
      PC_reg <= (22 => '1', others => '0'); -- 0040_0000
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
      elsif rising_edge(clk) and enable_IF_ID='1' then
        PC_ID<=PC_IF;
        instruction_ID<=instruccion_IF;
      end if;
    end process;

    enable_IF_ID<='1';
    IAddr<=PC_IF;
    PC_IF<=PC_reg;
    instruction<=IDataIn;

  PC_plus4    <= PC_reg + 4;
  Funct3      <= instruction(14 downto 12); -- Campo "funct3" de la instruccion
  Funct7      <= instruction(31 downto 25); -- Campo "funct7" de la instruccion
  RD          <= Instruction(11 downto 7);
  RS1         <= Instruction(19 downto 15);
  RS2         <= Instruction(24 downto 20);

-------ID/EX-----------------------------
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

        reg_RS1_EX <= (others => '0');
        reg_RS2_EX <= (others => '0');

        Ctrl_ALUSrc_EX<='0';
        Ctrl_ALUOP_EX<=(others => '0');

      elsif rising_edge(clk) and enable_ID_EX='1' then 
        PC_EX<=PC_ID;
        Funct3_EX<= Funct3_ID;  
        Funct7_EX<= Funct7_ID;
        Inm_ext_EX<=Inm_ext_ID;
        RD_EX <= RD_ID;

        Ctrl_Branch_EX <= Ctrl_Branch;
        Ctrl_ResSrc_EX <= Ctrl_ResSrc;
        Ctrl_MemWrite_EX<=Ctrl_MemWrite;
        Ctrl_MemRead_EX<=Ctrl_MemRead;
        Ctrl_PcLui_EX<=Ctrl_PcLui;
        Ctrl_jalr_EX<=Ctrl_jalr; 
        Ctrl_RegWrite_EX<=Ctrl_RegWrite;

        reg_RS1_EX <= reg_RS1_ID;
        reg_RS2_EX <= reg_RS2_ID;

        Ctrl_ALUSrc_EX<=Ctrl_ALUSrc;
        Ctrl_ALUOP_EX<=Ctrl_ALUOP;
      end if;
    end process;

    enable_ID_EX<='1';

    Addr_Branch_EX    <= PC_EX + Inm_ext_EX;
    Addr_jalr_EX    <= reg_RS1_EX + Inm_ext_EX;

    Alu_Op1_EX    <= PC_EX  when Ctrl_PcLui_EX = "00" else
                  (others => '0')  when Ctrl_PcLui_EX = "01" else
                  reg_RS1_EX;
    Alu_Op2_EX   <= reg_RS2_EX when Ctrl_ALUSrc_EX = '0' else Inm_ext_EX;
    
    Addr_Jump_dest_EX <= Addr_jalr_EX   when Ctrl_jalr_EX = '1' else
                      Addr_Branch_EX when Ctrl_Branch_EX='1' else
                      (others =>'0');


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
      reg_RS2_MEM<=(others => '0');
      Alu_Res_MEM<=(others => '0');

      Ctrl_ResSrc_MEM<= (others => '0');
      Ctrl_RegWrite_MEM<='0';
      
    elsif rising_edge(clk) and enable_EX_MEM='1' then 
      Addr_Jump_dest_MEM <= Addr_Jump_dest_EX;
      Ctrl_Jalr_MEM<=Ctrl_jalr_EX;
      Ctrl_Branch_MEM<=Ctrl_Branch_EX;

      Alu_ZERO_MEM<= Alu_ZERO_EX;
      Alu_SIGN_MEM<=Alu_SIGN_EX;

      Funct3_MEM<=Funct3_EX;

      Ctrl_MemWrite_MEM<= Ctrl_MemWrite_EX;
      Ctrl_MemRead_MEM<=Ctrl_MemRead_EX;

      RD_MEM<=RD_EX;
      reg_RS2_MEM<=reg_RS2_EX;
      Alu_Res_MEM<=Alu_Res_EX;

      Ctrl_ResSrc_MEM<= Ctrl_ResSrc_EX;
      Ctrl_RegWrite_MEM<=Ctrl_RegWrite_EX;

    end if;
  end process;

  enable_EX_MEM<='1';

  PC_next <= Addr_Jump_dest_MEM when decision_Jump_MEM = '1' else PC_plus4;

  decision_Jump_MEM  <= Ctrl_Jalr_MEM or (Ctrl_Branch_MEM and branch_true_MEM);

  branch_true_MEM    <= '1' when ( ((Funct3_MEM = BR_F3_BEQ) and (Alu_ZERO_MEM = '1')) or
  ((Funct3_MEM = BR_F3_BNE) and (Alu_ZERO_MEM = '0')) or
  ((Funct3_MEM = BR_F3_BLT) and (Alu_SIGN_MEM = '1')) or
  ((Funct3_MEM = BR_F3_BGT) and (Alu_SIGN_MEM = '0')) ) else '0';

  DWrEn<= Ctrl_MemWrite_MEM;
  dRdEn<= Ctrl_MemRead_MEM;
  DDataOut<= reg_RS2_MEM;
  DAddr<= Alu_Res_MEM;
  dataIn_MEM <= DDataIn;

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

  reg_RD_data_WB <= dataIn_WB when Ctrl_ResSrc_WB = "01" else
                   PC_plus4   when Ctrl_ResSrc_WB = "10" else 
                   Alu_Res_WB;


-------------------------------------


  RegsRISCV : reg_bank
  port map (
    Clk   => Clk,
    Reset => Reset,
    A1    => RS1, --Instruction(19 downto 15), --rs1
    Rd1   => reg_RS1,
    A2    => RS2, --Instruction(24 downto 20), --rs2
    Rd2   => reg_RS2,
    A3    => RD, --Instruction(11 downto 7),,
    Wd3   => reg_RD_data,
    We3   => Ctrl_RegWrite
  );

  UnidadControl : control_unit
  port map(
    OpCode   => Instruction(6 downto 0),
    -- Señales para el PC
    Branch   => Ctrl_Branch,
    Ins_Jal  => Ctrl_Jal,
    Ins_Jalr => Ctrl_Jalr,
    -- Señales para la memoria y seleccion dato escritura registros
    ResultSrc=> Ctrl_ResSrc,
    MemWrite => Ctrl_MemWrite,
    MemRead  => Ctrl_MemRead,
    -- Señales para la ALU
    ALUSrc   => Ctrl_ALUSrc,
    AuipcLui => Ctrl_PcLui,
    ALUOp    => Ctrl_ALUOp,
    -- Señales para el GPR
    RegWrite => Ctrl_RegWrite
  );

  immed_op : Imm_Gen
  port map (
        instr    => Instruction,
        imm      => Imm_ext 
  );

  Alu_control_i: alu_control
  port map(
    -- Entradas:
    ALUOp   => Ctrl_ALUOp, -- Codigo de control desde la unidad de control
    Funct3  => Funct3,    -- Campo "funct3" de la instruccion
    Funct7  => Funct7,    -- Campo "funct7" de la instruccion
    -- Salida de control para la ALU:
    ALUControl => AluControl -- Define operacion a ejecutar por la ALU
  );

  Alu_RISCV : alu_RV
  port map (
    OpA      => Alu_Op1,
    OpB      => Alu_Op2,
    Control  => AluControl,
    Result   => Alu_Res,
    Signflag => Alu_SIGN,
    CarryOut => open,
    Zflag    => Alu_ZERO
  );

  Alu_Op1    <= PC_reg           when Ctrl_PcLui = "00" else
                (others => '0')  when Ctrl_PcLui = "01" else
                reg_RS1; -- any other 
  Alu_Op2    <= reg_RS2 when Ctrl_ALUSrc = '0' else Imm_ext;


  DAddr      <= Alu_Res;
  DDataOut   <= reg_RS2;
  DWrEn      <= Ctrl_MemWrite;
  DRdEn      <= Ctrl_MemRead;
  dataIn_Mem <= DDataIn;

  reg_RD_data <= dataIn_Mem when Ctrl_ResSrc = "01" else
                 PC_plus4   when Ctrl_ResSrc = "10" else 
                 Alu_Res; -- When 00

end architecture;
