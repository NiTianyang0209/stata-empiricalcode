**# 内生性检验-豪斯曼检验 
reg Y X $CV
est sto ols 

ivregress 2sls Y $CV (X=IV) 
est sto tsls 

estat endogenous //豪斯曼检验与异方差稳健的DWH检验均拒绝了原假设(p=0.000),即认为X是一个内生变量
hausman tsls ols , cons sig


**# 内生性处理-工具变量法 
ivreghdfe Y $CV (X=IV) i.year i.id, cluster(clustervar) first savefirst savefprefix(f) partial(i.year i.id) 

* 结果输出 
ivreghdfe Y $CV (X=IV) i.year i.id, cluster(clustervar) first savefirst savefprefix(f) partial(i.year i.id) 
est sto gjbl01

estadd scalar F =`e(widstat)': fY

esttab fY gjbl01 using "工具变量法.rtf", ///
	scalar(idstat idp F) ///idstat是KP-LM统计量，idp是对应p值；F是KP-F统计量，用Stock-Yogo10%临界值进行判断
	replace star( * 0.10 ** 0.05 *** 0.01 ) ///
	order(Y IV) ///
	nogaps compress ///
	b(%20.3f) t(%7.3f)  ///
	title(regression result)

**# 内生性处理-PSM 
psestimate X, totry($CV) noquad //筛选协变量 

sort id year
xtset id year

set seed 12345678 
gen tmp=runiform() 
sort tmp
global CV_PSM "varlist" //

*PSM匹配
psmatch2 X $CV_PSM, out(Y) logit common ties ate n(1) //n(#)最近邻匹配1:n，cal(0.05)卡尺设置；kernel核匹配，带宽设置bw(0.01)；radius半径匹配

pstest $cv_psm, both graph

graph export "标准化偏差图示", as(png) name("Graph")  //输出成图片

*PSM匹配后回归：
reghdfe Y X $CV if _weight!=. ,absorb(id year) vce(robust) 
est sto psmreg 

/* 匹配前后核密度图
replace common=_support
drop if common==0
*-(a)before matching: 匹配前的密度函数图
twoway (kdensity _ps if _treat==1,lp(solid) lw(*2.5))   ///
       (kdensity _ps if _treat==0,lp(dash)  lw(*2.5)),  ///
        ytitle("核密度")  ylabel(,angle(0))                 ///
        xtitle("倾向得分值") xscale(titlegap(2)) xlabel(0(0.2)0.8, format(%2.1f))  ///
        legend(label(1 "处理组") label(2 "控制组") row(2) position(12) ring(0))    ///
        scheme(s1mono) name(match1,replace)
graph save psm_be, replace
			
*-(b)after matching: 匹配后的密度函数图
twoway (kdensity _ps if _treat==1,lp(solid) lw(*2.5))          ///
       (kdensity _ps if _treat==0&_wei!=.,lp(dash) lw(*2.5)),  ///
        ytitle("核密度") ylabel(,angle(0))                         ///
        xtitle("倾向得分值") xscale(titlegap(2)) xlabel(0(0.2)0.8, format(%2.1f))  ///
        legend(label(1 "处理组") label(2 "控制组") row(2) position(12) ring(0))    ///
        scheme(s1mono) name(match2,replace)
graph save psm_af, replace
graph combine psm_be.gph psm_af.gph,scheme(burd)

*/


**# 内生性处理-Heckman两步法 
xtset id year

probit X IV $CV
est sto hkm01

predict param_01, xb
gen IMR_01 = normalden(param_01)/normal(param_01) //计算逆米尔斯比
reghdfe Y X $CV IMR_01, absorb(year id) vce(cluster clustervar) 
est sto hkm02
