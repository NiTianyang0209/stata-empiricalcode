**# DID识别有效性-事前趋势检验 
gen policytime = year - policyyear //计算间隔年份
replace policytime = -5 if pt < -5 //归并到事前5期 
replace policytime = 5 if pt > 5 //归并到事后5期 
tab policytime, missing 

* 生成年份虚拟变量与实验组虚拟变量的交互项
forvalues i = 5(-1)1{
gen pre_`i' = (policytime == -`i' & treat == 1)
}
gen current = (policytime == 0 & treat == 1)
forvalues j = 1(1)5{
gen post_`j' = (policytime == `j' & treat == 1)
}

* 事前趋势检验回归 
reghdfe Y pre_5 pre_4 pre_3 pre_2 current post_1 post_2 post_3 post_4 post_5 $CV, ab(id year) vce(cluster clustervar) //不表示基期-1

reghdfe Y pre_5 pre_4 pre_3 pre_2 current post_1 post_2 post_3 post_4 post_5 pre_1 $CV, ab(id year) vce(cluster clustervar) //表示基期-1（末尾增加pre_1）

* 政策动态效应图
coefplot, baselevels vertical keep(pre_* current post_*) omitted ///
order(pre_5 pre_4 pre_3 pre_2 pre_1 current post_1 post_2 post_3 post_4 post_5) ///
level(95) ///
yline(0,lcolor(edkblue*0.8)) xline(6, lwidth(thin) lpattern(shortdash) lcolor(teal)) ///
ylabel(,labsize(*0.75) format(%7.3f) angle(0)) ///
xlabel(,labsize(*0.75)) ///
ytitle("政策动态效应", size(small)) ///
xtitle("政策相对时点", size(small)) ///
addplot(line @b @at) ciopts(lpattern(line) recast(rcap) msize(medium)) msymbol(circle_hollow) scheme(s1mono)

* 结果输出
reghdfe Y pre_5 pre_4 pre_3 pre_2 current post_1 post_2 post_3 post_4 post_5 pre_1 $CV, ab(id year) vce(cluster clustervar)
est sto sbyxx01 

esttab sbyxx01 using "事前趋势检验.rtf", ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress ///
	b(%20.3f) t(%7.3f)  ///
	scalars(r2_within) ///
	indicate(`r(indicate_fe)') ///
	order(X) ///
	mtitles("Y") ///
	title(regression result)


**# DID识别有效性-平行趋势敏感性分析 
mat list e(b) 
local plotopts xtitle(平行趋势偏离的相对程度Mbar) ytitle(90%稳健置信区间) title(相对偏离程度限制) graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white)) scheme(s1mono) 

* 相对偏离程度限制 90%区间，0.5倍
honestdid, pre(1/4) post(5/10) mvec(0(0.1)0.5) alpha(0.1) coefplot `plotopts'

* post_1 0.1可以
matrix l_vec = 0 \ 1 \ 0 \ 0 \ 0 \ 0  
local plotopts xtitle(平行趋势偏离的相对程度Mbar) ytitle(90%稳健置信区间) title(相对偏离程度限制) graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white)) scheme(s1mono) 
* 相对偏离程度限制 90%区间，0.5倍
honestdid, l_vec(l_vec) pre(1/4) post(5/10) mvec(0(0.1)0.5) alpha(0.1) coefplot `plotopts' 

* 第三期 0.1可以
matrix l_vec = 0 \ 0 \ 1 \ 0 \ 0 \ 0  
local plotopts xtitle(平行趋势偏离的相对程度Mbar) ytitle(90%稳健置信区间) title(相对偏离程度限制) graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white)) scheme(s1mono) 
* 相对偏离程度限制 90%区间，0.5倍
honestdid, l_vec(l_vec) pre(1/4) post(5/10) mvec(0(0.1)0.5) alpha(0.1) coefplot `plotopts' 

* 第五期 0.1可以
matrix l_vec = 0 \ 0 \ 0 \ 0 \ 1 \ 0  
local plotopts xtitle(平行趋势偏离的相对程度Mbar) ytitle(90%稳健置信区间) title(相对偏离程度限制) graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white)) scheme(s1mono) 
* 相对偏离程度限制 90%区间，0.5倍
honestdid, l_vec(l_vec) pre(1/4) post(5/10) mvec(0(0.1)0.5) alpha(0.1) coefplot `plotopts' 

* 五期平均 0.1可以
matrix l_vec = 0 \ 0.2 \ 0.2 \ 0.2 \ 0.2 \ 0.2  
local plotopts xtitle(平行趋势偏离的相对程度Mbar) ytitle(90%稳健置信区间) title(相对偏离程度限制) graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white)) scheme(s1mono) 
* 相对偏离程度限制 90%区间，0.5倍
honestdid, l_vec(l_vec) pre(1/4) post(5/10) mvec(0(0.1)0.5) alpha(0.1) coefplot `plotopts' 

graph combine graph01.gph graph.gph, row(1)


**# DID识别有效性-异质性处理效应 
ddtiming Y X, i(id) t(year)  
bacondecomp Y X, ddetail //"晚处理vs早处理"权重要小 

* 负权重问题de Chaisemartin & D'Haultfoeuille(2020) 
twowayfeweights Y id year X, type(feTR) controls($CV) //

* de Chaisemartin & D'Haultfoeuille(2020)估计量——did_multiplegt_dyn  
did_multiplegt_dyn Y id year X, effects(n) placebo(m) controls($CV) //m<=n

event_plot e(estimates)#e(variances),  default_look shift(1) graph_opt(xt("政策相对时点") yt("政策动态效应") title("de Chaisemartin & D'Haultfoeuille(2020)估计量") xlabel(-4(1)4)) stub_lag(Effect_#) stub_lead(Placebo_#) ciplottype(rarea) together alpha(0.1) // 


* Callaway & Sant'Anna(2021)估计量——csdid
gen action = policyyear 
replace action=0 if action==.
order action, after(policyyear)

csdid Y $CV, time(year) gvar(action) ivar(id) notyet method(stdipw)

estat simple 
estat event, window(-5,4)
csdid_plot, style(rcap) scale(1.0) xt("政策相对时点") yt("平均处理效应") title("Callaway & Sant'Anna(2021)估计量") 


* Sun & Abraham(2021)估计量——eventstudyinteract 
gen action_01 = action 
replace action_01=. if action_01==0
gen never=1 if action_01==.
replace never=0 if never==.
order action_01 never, after(action)

eventstudyinteract Y pre_5 pre_4 pre_3 pre_2 current post_1 post_2 post_3 post_4 post_5 pre_1, cohort(action_01) control_cohort(never) covariates($CV) absorb(id year) vce(robust) 

matrix b = e(b_iw) 
matrix V = e(V_iw) 
ereturn post b V 

* 政策动态效应图
coefplot, baselevels vertical keep(pre_* current post_*) omitted ///
order(pre_5 pre_4 pre_3 pre_2 pre_1 current post_1 post_2 post_3 post_4 post_5) ///
level(95) ///
yline(0,lcolor(edkblue*0.8)) xline(6, lwidth(thin) lpattern(shortdash) lcolor(teal)) ///
ylabel(,labsize(*0.75) format(%7.3f) angle(0)) ///
xlabel(,labsize(*0.75)) ///
ytitle("政策动态效应", size(small)) ///
xtitle("政策相对时点", size(small)) ///
title("Sun & Abraham(2021)估计量") ///
addplot(line @b @at) ciopts(lpattern(line) recast(rcap) msize(medium)) msymbol(circle_hollow) scheme(s1mono)

lincom(current + post_1 + post_2 + post_3 + post_4)/5 //
lincom(current + post_1 + post_2 + post_3 + post_4 + post_5)/6 //


* 插补估计量Borusyak et al.(2021)——did_imputation
did_imputation Y id year action_01, horizons(0/4) pretrends(4) autosample controls($CV) fe(id year) tol(1) minn(1) maxit(100) 

event_plot, default_look graph_opt(xt("政策相对时点") yt("政策动态效应") title("Borusyak et al.(2021)估计量") xlabel(-5(1)5)) ciplottype(rcap) together alpha(0.05) // 


* 堆叠回归估计量Cengiz et al.(2019)——stackedev 
stackedev Y pre_5 pre_4 pre_3 pre_2 current post_1 post_2 post_3 post_4 post_5 pre_1, cohort(action_01) time(year) never_treat(never) unit_fe(id) clust_unit(id) covariates($CV) 

lincom(current + post_1 + post_2 + post_3 + post_4 + post_5)/6 //

* 政策动态效应图
coefplot, baselevels vertical keep(pre_* current post_*) omitted ///
order(pre_5 pre_4 pre_3 pre_2 pre_1 current post_1 post_2 post_3 post_4 post_5) ///
level(95) ///
yline(0,lcolor(edkblue*0.8)) xline(6, lwidth(thin) lpattern(shortdash) lcolor(teal)) ///
ylabel(,labsize(*0.75) format(%7.3f) angle(0)) ///
xlabel(,labsize(*0.75)) ///
ytitle("政策动态效应", size(small)) ///
xtitle("政策相对时点", size(small)) ///
title("Cengiz et al.(2019)估计量") ///
addplot(line @b @at) ciopts(lpattern(line) recast(rcap) msize(medium)) msymbol(circle_hollow) scheme(s1mono)


**# DID识别有效性-安慰剂检验
reghdfe Y DID $CV, ab(id year) vce(cluster clustervar)  //

estimates store abc 

didplacebo abc, treatvar(DID) pbotime(1(1)4) //时间安慰剂，置信区间都包含0

didplacebo abc, treatvar(DID) pbounit rep(500) seed(12345678) //空间安慰剂，双边p值 

didplacebo abc, treatvar(DID) pbomix(2) seed(12345678) //无约束混合安慰剂，双边p值 

didplacebo abc, treatvar(DID) pbomix(3) seed(12345678) //有约束混合安慰剂，双边p值 

graph combine sbyxx04-1.gph sbyxx04-2.gph sbyxx04-3.gph sbyxx04-4.gph, row(2)
