* 设置正向指标
global var_posi "  "

* 设置负向指标
global var_nega "  " 

* 1. 变量标准化 (正向指标)
foreach v in $var_posi {
    egen min_`v' = min(`v')
    egen max_`v' = max(`v')
    gen z_`v' = (`v' - min_`v') / (max_`v' - min_`v')
    replace z_`v' = z_`v' + 0.00001  // 修正零值
}

* 变量标准化 (负向指标)
foreach v in $var_nega {
    egen min_`v' = min(`v')
    egen max_`v' = max(`v')
    gen z_`v' = (max_`v' - `v') / (max_`v' - min_`v')
	replace z_`v' = z_`v' + 0.00001  // 修正零值
} 

global z_var "z_**" // 标准化后的数值z_

* 2. 计算比重 P
foreach v in $z_var {
    egen sum_`v' = sum(`v')
    gen p_`v' = `v' / sum_`v'
}

global p_var "p_z_**" //计算出的比重p_

* 3. 计算熵值 E
count
local n = r(N)
foreach v in $p_var {
    gen lp_`v' = `v' * ln(`v')
    egen sum_lp_`v' = sum(lp_`v')
    gen e_`v' = -1/ln(`n') * sum_lp_`v'
}

global e_var "e_p_z_**" // 保存熵值为e_

* 4. 计算权重 W
gen sum_d = 0
foreach v in $e_var {
    gen d_`v' = 1 - `v'
    replace sum_d = sum_d + d_`v'
}

global d_var "d_e_p_z_**" // 

foreach v in $d_var {
    gen w_`v' = `v' / sum_d
    sum w_`v' // 查看各指标权重
}

global w_var "w_d_e_p_z_**" // 保存权重为w_

* 设定参与熵值计算的所有变量，务必对应权重计算的变量顺序
global AA "  "

* 5. 计算综合得分
local Xlist $AA
local Wlist $w_var 

gen score = 0

local n : word count `Xlist'

forvalues i = 1/`n' {
    local x : word `i' of `Xlist'
    local w : word `i' of `Wlist'
    
    replace score = score + `x' * `w'
}

sum score // 熵值法综合指标score计算完成

