library ieee;

use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity simulation is
generic (

		--NCO
		NCO_SIZE : natural := 16;
		DATA_IN : natural := 16;	
				
		--Filtre_1
		DECIMATE_FACTOR_fir_1 : natural := 10;
		DATA_IN_SIZE_fir_1 : natural := 16;
		DATA_OUT_SIZE_fir_1: natural := 23;
		NB_COEFF : natural := 25;
		COEFF_SIZE: natural := 16;
		--shifterComplex_dyn_1
		
		DEFAULT_SHIFT_dyn_1 : natural := 2;
		DATA_IN_SIZE_dyn_1  : natural := 23;
		DATA_OUT_SIZE_dyn_1 : natural := 20;		
		---Filtre 2
		DATA_IN_SIZE_fir_2 : natural :=20;
		DATA_OUT_SIZE_fir_2 : natural :=41;
		DECIMATE_FACTOR_fir_2 : natural := 10;

		------------------------
		--shifterComplex_dyn_2
		
		DEFAULT_SHIFT_dyn_2 : natural := 2;
		DATA_IN_SIZE_dyn_2  : natural := 41;
		DATA_OUT_SIZE_dyn_2 : natural := 28;
		
		
		--shifterReal_dyn
		SIGNED_DATA_shiftReal_dyn  : boolean := true;
		DEFAULT_SHIFT_shiftReal_dyn: natural := 0;
		DATA_IN_SIZE_shiftReal_dyn : natural := 56;
		DATA_OUT_SIZE_shiftReal_dyn: natural := 14;
		
		
		--PID3
		P_SIZE : integer := 14;
		PSR : integer := 1; --PSR_SIZE
		I_SIZE : integer := 18;
		ISR : integer := 13;
		D_SIZE : integer := 14;
		DSR : integer := 1;
		DATA_IN_SIZE_pid : natural := 14;
		DATA_OUT_SIZE_pid : natural := 30;
		
		----ShiftReal_end
		--DATA_in_SIZE_shiftReal : natural := 30;
		DATA_OUT_SIZE_shiftReal : natural := 14

	);

port (
	
		clk_i : in std_logic;--horloge
		rst_i : in std_logic;--reset

		-- NCO interface
		nco_i_i : in std_logic_vector(16-1 downto 0);
		nco_q_i : in std_logic_vector(16-1 downto 0);
		nco_en_i : in std_logic;
		
		-- ADC interface
		adc_en_i : in std_logic;
		data_i: in std_logic_vector(16-1 downto 0);
		data_en_o : out std_logic;
		data_i_o : out std_logic_vector(DATA_OUT_SIZE_shiftReal-1 downto 0);
		data_q_o : out std_logic_vector(DATA_OUT_SIZE_shiftReal-1 downto 0);
		
		
		----PID
		kp_i        : in std_logic_vector(P_SIZE-1 downto 0) := (P_SIZE-1 downto 0 => '0');
        ki_i        : in std_logic_vector(I_SIZE-1 downto 0) := (I_SIZE-1 downto 0 => '0');
        kd_i        : in std_logic_vector(D_SIZE-1 downto 0) := (D_SIZE-1 downto 0 => '0');
        pid_int_rst_i : in std_logic;
		pid_setpoint_i : in std_logic_vector(DATA_IN_SIZE_pid-1 downto 0);
        pid_sign_i  : in std_logic;
        
        --Filtre
        coeff_en_i_fir_1    : in  std_logic;
		coeff_en_i_fir_2    : in std_logic

			
	);
	
end simulation;

architecture Behavioral of simulation is
--partie mixer
signal mixer_en_o : std_logic;		
signal mixer_i_o  :std_logic_vector(15 downto 0);
signal mixer_q_o :std_logic_vector(15 downto 0);

--fir_1
constant data_out_filt_1_to_shiftC_dyn : natural := DATA_OUT_SIZE_fir_1;
constant data_in_size_fir_1_to_shifterDyn_1: natural := DATA_IN_SIZE_fir_1;
signal Data_out_filter_1_en_o_to_shiftC_dyn1_s : std_logic;		
signal Data_out_filter_1_i_o_to_shitftC_dyn1_s  :std_logic_vector(data_out_filt_1_to_shiftC_dyn-1 downto 0);
signal Data_out_filter_1_q_o_to_shitftC_dyn1_s :std_logic_vector(data_out_filt_1_to_shiftC_dyn-1 downto 0);

--ShifterComplexDyn_dyn_1
constant data_out_size_dyn_1_to_fir_2 : natural := DATA_OUT_SIZE_dyn_1;
signal Data_out_shifterComplex_dyn_1_en_o: std_logic;		
signal Data_out_shifterComplex_dyn_1_i_o  :std_logic_vector(data_out_size_dyn_1_to_fir_2-1 downto 0);
signal Data_out_shifterComplex_dyn_1_q_o :std_logic_vector(data_out_size_dyn_1_to_fir_2-1 downto 0);

--Filter_2
signal Data_out_filter_2_en_o : std_logic;		
signal Data_out_filter_2_i_o  :std_logic_vector(DATA_OUT_SIZE_fir_2-1 downto 0);
signal Data_out_filter_2_q_o :std_logic_vector(DATA_OUT_SIZE_fir_2-1 downto 0);

--ShifterDyn_2
signal Data_out_ShifterComplex_dyn_2_en_o : std_logic;	
signal Data_out_shifterComplex_dyn_2_i_o  :std_logic_vector(DATA_OUT_SIZE_dyn_2-1 downto 0);
signal Data_out_shifterComplex_dyn_2_q_o :std_logic_vector(DATA_OUT_SIZE_dyn_2-1 downto 0);

--MAG
constant DATA_OUT_SIZE_dyn_2_to_mag : natural := DATA_OUT_SIZE_dyn_2;
constant DATA_OUT_SIZE_dyn_2_to_mag_i_o_tmp : natural := DATA_OUT_SIZE_dyn_2_to_mag * 2;
constant DATA_OUT_SIZE_dyn_2_to_mag_tmp2 : natural:= DATA_OUT_SIZE_dyn_2_to_mag_i_o_tmp;


signal  DATA_OUT_MAG_i_o : signed(DATA_OUT_SIZE_dyn_2_to_mag_i_o_tmp-1 downto 0);
signal  DATA_OUT_MAG_q_o : signed(DATA_OUT_SIZE_dyn_2_to_mag_i_o_tmp-1 downto 0);
signal DATA_OUT_MAG_s : std_logic_vector(DATA_OUT_SIZE_dyn_2_to_mag_tmp2-1 downto 0);


signal Data_out_ShifterReal_dyn_to_PI_en_o : std_logic;	
signal Data_out_ShifterReal_dyn_to_PI_i_o  :std_logic_vector(DATA_OUT_SIZE_shiftReal_dyn-1 downto 0);

--PID
signal sign2_s    : std_logic;
signal setpoint_s : std_logic_vector(DATA_IN_SIZE_pid-1 downto 0);
signal setpoint2_s: std_logic_vector(DATA_IN_SIZE_pid-1 downto 0);

signal int_rst2_s : std_logic;



signal Data_out_PID_to_shiftReal_en_o : std_logic;	
signal Data_out_PID_to_shiftReal_i_o  :std_logic_vector(DATA_OUT_SIZE_pid-1 downto 0);

----shifterComplex dyn 1 
		constant SIGNED_FORMAT : boolean := true;
		constant MAX_SHIFT_dyn_1      : natural := DATA_IN_SIZE_dyn_1 - data_out_size_dyn_1_to_fir_2 + 1;
		constant SHFT_ADDR_SZ_dyn_1   : natural := natural(ceil(log2(real(MAX_SHIFT_dyn_1))));
		signal shift_val_i_dyn_1: std_logic_vector(SHFT_ADDR_SZ_dyn_1-1 downto 0);

----shifterComplex dyn 2
		constant MAX_SHIFT_dyn_2      : natural := DATA_IN_SIZE_dyn_2 - DATA_OUT_SIZE_dyn_2 + 1;
		constant  SHFT_ADDR_SZ_dyn_2   : natural := natural(ceil(log2(real(MAX_SHIFT_dyn_2))));
		signal shift_val_i_dyn_2: std_logic_vector(SHFT_ADDR_SZ_dyn_2-1 downto 0);

--shifterReal_dyn
		constant DATA_IN_SIZE_shiftReal_dyn_to_pid : natural := DATA_IN_SIZE_shiftReal_dyn;
		constant MAX_SHIFT_real_dyn      : natural := DATA_IN_SIZE_shiftReal_dyn_to_pid - DATA_OUT_SIZE_shiftReal_dyn + 1;
		constant SHIFT_ADDR_SZ_real_dyn_1 : natural := natural(ceil(log2(real(MAX_SHIFT_real_dyn))));
		signal SHIFT_val_real_dyn_1 : std_logic_vector(SHIFT_ADDR_SZ_real_dyn_1 -1 downto 0);


-- Filtre 
		constant COEFF_ADDR_SZ : natural := natural(ceil(log2(real(NB_COEFF))));      		                                                                                               
        signal coeff_i       : std_logic_vector(COEFF_SIZE-1 downto 0);
        signal coeff_addr_i  :  std_logic_vector(COEFF_ADDR_SZ-1 downto 0);
	    constant coeff_format : string := "signed";
	        
begin
  
	--mixer_sin
	mixer_inst: entity work.mixer_sin
	generic map (NCO_SIZE => 16,
		DATA_IN_SIZE => 16, DATA_OUT_SIZE => 16
	)
	port map (data_clk_i => clk_i, data_rst_i => rst_i,
		data_en_i => adc_en_i, data_i => data_i,
		nco_clk_i => clk_i, nco_rst_i => rst_i,
		nco_i_i => nco_i_i, nco_q_i => nco_q_i, nco_en_i => nco_en_i,
		data_en_o => mixer_en_o, data_i_o => mixer_i_o, data_q_o => mixer_q_o
	);
	
	
	--filtre 1
	fir_1_inst : entity work.firComplex_top
	generic map (
		COEFF_ADDR_SZ => COEFF_ADDR_SZ,
		coeff_format => coeff_format,
		NB_COEFF => NB_COEFF,
		DECIMATE_FACTOR => DECIMATE_FACTOR_fir_1,
		COEFF_SIZE => COEFF_SIZE,
		DATA_SIZE  => data_in_size_fir_1_to_shifterDyn_1,
		DATA_OUT_SIZE  => data_out_filt_1_to_shiftC_dyn
	)
	port map (
		-- Syscon signals
		clk		=> clk_i,
		clk_axi => clk_i,
		reset		 	=> rst_i,
		--simulation
		wr_coeff_en_i 	=> coeff_en_i_fir_1,
		wr_coeff_addr_i => coeff_addr_i,
		wr_coeff_val_i 	=> coeff_i,
		-- input data
		data_en_i	=> mixer_en_o,
		data_i_i	=> mixer_i_o,
		data_q_i	=> mixer_q_o,
		
		data_en_o	=> Data_out_filter_1_en_o_to_shiftC_dyn1_s,
		data_i_o	=> Data_out_filter_1_i_o_to_shitftC_dyn1_s ,
		data_q_o	=> Data_out_filter_1_q_o_to_shitftC_dyn1_s

	);
	
	
	--------ShifterComplex dyn 1
	shift_dyn1 : entity work.shifterComplex_dyn_logic
	generic map (SIGNED_FORMAT  => SIGNED_FORMAT , MAX_SHIFT => MAX_SHIFT_dyn_1,
		ADDR_SZ => SHFT_ADDR_SZ_dyn_1,
		DATA_IN_SIZE => DATA_IN_SIZE_dyn_1, DATA_OUT_SIZE => data_out_size_dyn_1_to_fir_2)
	port map(clk_i => clk_i, rst_i => rst_i,
		shift_val_i => shift_val_i_dyn_1,
		-- input
		data_i_i => Data_out_filter_1_i_o_to_shitftC_dyn1_s, data_q_i => Data_out_filter_1_q_o_to_shitftC_dyn1_s, data_en_i => Data_out_filter_1_en_o_to_shiftC_dyn1_s,
		data_eof_i => '0', data_sof_i => '0',
		--for next
		data_i_o => Data_out_shifterComplex_dyn_1_i_o, data_q_o => Data_out_shifterComplex_dyn_1_q_o, data_en_o => Data_out_shifterComplex_dyn_1_en_o,
		data_eof_o => open, data_sof_o => open);
	
	
	--------------------------------
	---Filtre complex 2 
	
	fir_2_inst_2 : entity work.firComplex_top
	generic map (
		COEFF_ADDR_SZ => COEFF_ADDR_SZ,
		coeff_format => coeff_format,
		NB_COEFF => NB_COEFF,
		DECIMATE_FACTOR => DECIMATE_FACTOR_fir_2,
		COEFF_SIZE => COEFF_SIZE,
		DATA_SIZE  => DATA_IN_SIZE_fir_2,
		DATA_OUT_SIZE  => DATA_OUT_SIZE_fir_2
	)
	port map (
		-- Syscon signals
		clk		=> clk_i,
		clk_axi => clk_i,
		reset		 	=> rst_i,
		--simulation
		wr_coeff_en_i 	=> coeff_en_i_fir_2 ,
		wr_coeff_addr_i => coeff_addr_i,
		wr_coeff_val_i 	=> coeff_i ,
		-- input data
		data_en_i	=> Data_out_shifterComplex_dyn_1_en_o,
		data_i_i	=> Data_out_shifterComplex_dyn_1_i_o,
		data_q_i	=> Data_out_shifterComplex_dyn_1_q_o,
		
		data_en_o	=> Data_out_filter_2_en_o,
		data_i_o	=> Data_out_filter_2_i_o ,
		data_q_o	=> Data_out_filter_2_q_o

	);
	
		--------ShifterComplex dyn 2
	shift_dyn2 : entity work.shifterComplex_dyn_logic
	generic map (SIGNED_FORMAT  => SIGNED_FORMAT , MAX_SHIFT => MAX_SHIFT_dyn_2,
		ADDR_SZ => SHFT_ADDR_SZ_dyn_2,
		DATA_IN_SIZE => DATA_IN_SIZE_dyn_2, DATA_OUT_SIZE => DATA_OUT_SIZE_dyn_2)
	port map(clk_i => clk_i, rst_i => rst_i,
		shift_val_i => shift_val_i_dyn_2,
		-- input
		data_i_i => Data_out_filter_2_i_o, data_q_i => Data_out_filter_2_q_o, data_en_i => Data_out_filter_2_en_o,
		data_eof_i => '0', data_sof_i => '0',
		--for next
		data_i_o => Data_out_shifterComplex_dyn_2_i_o, data_q_o => Data_out_shifterComplex_dyn_2_q_o, data_en_o => Data_out_ShifterComplex_dyn_2_en_o,
		data_eof_o => open, data_sof_o => open);
		
		----------MAGNITUDE
DATA_OUT_MAG_i_o <= signed(Data_out_shifterComplex_dyn_2_i_o) * signed(Data_out_shifterComplex_dyn_2_i_o);
DATA_OUT_MAG_q_o <= signed(Data_out_shifterComplex_dyn_2_q_o) * signed(Data_out_shifterComplex_dyn_2_q_o);
DATA_OUT_MAG_s <= std_logic_vector(DATA_OUT_MAG_i_o + DATA_OUT_MAG_q_o);

		------ShifterReal_dyn
		shift_Real_dyn_1 : entity work.shifterReal_dyn_logic
	generic map (SIGNED_FORMAT => SIGNED_FORMAT, MAX_SHIFT => MAX_SHIFT_real_dyn,
		ADDR_SZ => SHIFT_ADDR_SZ_real_dyn_1,
		DATA_IN_SIZE => DATA_OUT_SIZE_dyn_2_to_mag_tmp2, DATA_OUT_SIZE => DATA_OUT_SIZE_shiftReal_dyn)
	port map(clk_i => clk_i, rst_i => rst_i,
		shift_val_i => SHIFT_val_real_dyn_1 ,
		-- input
		data_i => DATA_OUT_MAG_s, data_en_i => Data_out_ShifterComplex_dyn_2_en_o,
		data_eof_i => '0', data_sof_i => '0',
		--for next
		data_o => Data_out_ShifterReal_dyn_to_PI_i_o, data_en_o => Data_out_ShifterReal_dyn_to_PI_en_o,
		data_eof_o => open, data_sof_o => open);
		
		-----PID3
		
		pidv3_axiLogic : entity work.pidv3_axi_logic
	generic map(DATA_IN_SIZE => DATA_IN_SIZE_pid, DATA_OUT_SIZE => DATA_OUT_SIZE_pid,
	P_SIZE => P_SIZE, I_SIZE => I_SIZE, D_SIZE => D_SIZE,
	ISR => ISR, PSR => PSR, DSR => DSR)
	port map (clk_i => clk_i, reset => rst_i,
		data_i => Data_out_ShifterReal_dyn_to_PI_i_o, data_en_i  => Data_out_ShifterReal_dyn_to_PI_en_o,
		data_o => Data_out_PID_to_shiftReal_i_o, data_en_o=> data_out_PID_to_shiftReal_en_o,
		setpoint_i => pid_setpoint_i, 
		kp_i => kp_i, ki_i => ki_i, kd_i => kd_i,
		sign_i => pid_sign_i, int_rst_i => pid_int_rst_i
	);
	
	
    
    shift_Real : entity work.shifterReal
    generic map(
		DATA_IN_SIZE => DATA_OUT_SIZE_pid,
		DATA_OUT_SIZE => DATA_out_SIZE_shiftReal
	)
	port map(
		-- input data
		data_i => Data_out_PID_to_shiftReal_i_o ,
		data_en_i =>  data_out_PID_to_shiftReal_en_o,
		data_eof_i =>'0',
		data_clk_i => clk_i,
		data_rst_i =>rst_i,
		-- for the next component
		data_o  => data_i_o	,
		data_en_o => data_en_o,
		data_eof_o => open,
		data_rst_o  => open,
		data_clk_o  => open
	);
    
end architecture Behavioral;
