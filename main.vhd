library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity main_block is
	Port (X: in std_logic_vector(31 downto 0);
	      Y: in std_logic_vector(31 downto 0);
	      R: out std_logic_vector(31 downto 0)
		 );
end main_block;

architecture behav of main_block is

-- exponent comparator
component cmp_exp is
  Port (Ex: in std_logic_vector(7 downto 0);
        Ey: in std_logic_vector(7 downto 0);
        EQ: out std_logic; -- '1' if Ex = Ey
        GT: out std_logic; -- '1' if Ex > Ey
        LT: out std_logic  -- '1' if Ex < Ey
        );
end component;

signal Mx, My, Mr: std_logic_vector(24 downto 0);
signal Ex, Ey, Er: std_logic_vector(7 downto 0);
signal Sx, Sy, Sr: std_logic;

signal expEQ, expGT, expLT: std_logic;


begin
	-- retrieving X, Y sign bit
	Sx <= X(31);
	Sy <= Y(31);
	
	-- retrieving X, Y mantissa and concatenate two bits: the leading bit 1 and a carry out bit
	Mx <= "01" & X(22 downto 0);
	My <= "01" & Y(22 downto 0);
	
	-- retrieving X, Y exponent
	Ex <= X(30 downto 23);
	Ey <= Y(30 downto 23);
	
	exponent_cmp: cmp_exp port map(Ex => Ex, Ey => Ey, EQ => expEQ, GT => expGT, LT => expLT);
	
	process(X, Y)
		variable d: signed(7 downto 0);
	begin
		if expGT = '1' then -- Ex > Ey
			d := signed(Ex) - signed(Ey);
			if d < 23 then
				Er <= Ex;
				My <= std_logic_vector(shift_right(unsigned(My), to_integer(d)));
			else
				R <= X;
			end if;
		elsif expLT = '1' then -- Ex < Ey
			d :=  signed(Ey) - signed(Ex);
			if d < 23 then
				Er <= Ey;
				Mx <= std_logic_vector(shift_right(unsigned(Mx), to_integer(d)));
			else
				R <= Y;
			end if;
		else -- Ex = Ey
			Er <= Ey;
		end if;
		
		
		-- addition
		if (Sx xor Sy) = '0' then -- same signs
			Mr <= std_logic_vector((unsigned(Mx) + unsigned(My)));
			Sr <= Sx;
		elsif unsigned(Mx) >= unsigned(My) then
			Mr <= std_logic_vector((unsigned(Mx) - unsigned(My)));
			Sr <= Sx;
		else
			Mr <= std_logic_vector((unsigned(My) - unsigned(Mx)));
			Sr <= Sb;
		end if;
		
		-- normalization
		if unsigned(Mr) = to_unsigned(0, 25) then
			Mr <= (others => '0');
			Er <= (others => '0');
		elsif Mr(24) = '1' then -- overflow sum of the mantissa, right shift performed and exponent incremented
			Mr <= '0' & Mr(24 downto 1);
			Er <= std_logic_vector((unsigned(Er) + 1));
		elsif Mr(23) = '0' then -- left shift
			Mr <= mr(23 downto 0) & '0';
			Er <= std_logic_vector((unsigned(Er) - 1));
		else
			R <= (others => 'U');
		end if;
	end process;
	
	R(31) <= Sr;
	R(30 downto 23) <= Er;
	R(22 downto 0)  <= Mr(22 downto 0);
end behav;