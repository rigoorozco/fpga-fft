library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
--use work.barrelShifter;

-- phase should be 0,1,2,3,4,5,6,... up to (2**N1)*(2**N2)-1
entity transposer_addrgen is
	generic(N1,N2: integer; -- N1 is the major size and N2 the minor size (input perspective)
			-- when phaseAdvance is 0, addr always corresponds to phase in the same clock cycle
			-- when phaseAdvance > 0, addr corresponds to phase+phaseAdvance
			phaseAdvance: integer := 0);
	port(clk: in std_logic;
		reorderEnable: in std_logic;
		phase: in unsigned(N1+N2-1 downto 0);
		addr: out unsigned(N1+N2-1 downto 0)
		);
end entity;
architecture ar of transposer_addrGen is
	signal ph1,ph2,ph3: unsigned(N1+N2-1 downto 0) := (others => '0');
	
	constant use_stagedBarrelShifter: boolean := false;
	constant stateCount: integer := N1+N2;
	constant stateBits: integer := ceilLog2(stateCount);
	--constant shifterMuxStages: integer := integer(ceil(real(stateBits)/real(2)));
	--constant shifterMuxBits: integer := shifterMuxStages*2;
	--constant delay: integer := iif(use_stagedBarrelShifter, shifterMuxStages+2, 3);
	constant extraRegister: boolean := ((N1+N2) >= 12);
	constant delay: integer := 3 + iif(extraRegister, 1, 0);
	--attribute delay of ar:architecture is shifterMuxStages+1;
	
	signal state,stateNext: unsigned(stateBits-1 downto 0) := (others=>'0');

	function is_clean_zero(v : unsigned) return boolean is
	begin
		for i in v'range loop
			if v(i) /= '0' then
				return false;
			end if;
		end loop;
		return true;
	end function;

	function add_mod_clean(cur : unsigned; step, modulus : natural) return unsigned is
		variable cur_i  : natural;
		variable next_i : natural;
	begin
		for i in cur'range loop
			if cur(i) /= '0' and cur(i) /= '1' then
				return to_unsigned(0, cur'length);
			end if;
		end loop;
		cur_i := to_integer(cur);
		next_i := cur_i + step;
		if next_i >= modulus then
			next_i := next_i - modulus;
		end if;
		return to_unsigned(next_i, cur'length);
	end function;
begin
	ph1 <= phase+phaseAdvance+delay when rising_edge(clk);
	-- 1 cycle
	
	ph2 <= ph1 when rising_edge(clk);
	stateNext <= add_mod_clean(state, N2, stateCount);
	state <= stateNext when is_clean_zero(ph1) and reorderEnable='1' and rising_edge(clk);
	-- 2 cycles
	
--g1:
--	if use_stagedBarrelShifter generate
--		bs: entity barrelShifter generic map(N1+N2, shifterMuxStages)
--				port map(clk, ph2, resize(state, shifterMuxBits), ph3);
--	end generate;
	-- 2+shifterMuxStages cycles
g2:
	if not use_stagedBarrelShifter generate
		ph3 <= rotate_left(ph2, to_integer(state)) when rising_edge(clk);
	end generate;
	-- 3 cycles
	
g3: if extraRegister generate
		addr <= ph3 when rising_edge(clk);
	end generate;
g4: if not extraRegister generate
		addr <= ph3;
	end generate;
end ar;
