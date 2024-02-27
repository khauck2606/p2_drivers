100-day mission: Model description
================

- [1 Simulation rules](#1-simulation-rules)
- [2 Socio-economic costs](#2-socio-economic-costs)
  - [2.1 Lost lives](#21-lost-lives)
  - [2.2 Lost economic output](#22-lost-economic-output)
  - [2.3 Lost education](#23-lost-education)
- [3 Epi model](#3-epi-model)
  - [3.1 Ordinary differential
    equations](#31-ordinary-differential-equations)
  - [3.2 Disease state transitions](#32-disease-state-transitions)
  - [3.3 Vaccination state
    transitions](#33-vaccination-state-transitions)
  - [3.4 Contact rates](#34-contact-rates)
    - [3.4.1 Matrix $A$: community
      contacts](#341-matrix-a-community-contacts)
    - [3.4.2 Matrix $B$: Worker-to-worker
      contacts](#342-matrix-b-worker-to-worker-contacts)
    - [3.4.3 Matrix $C$: Consumer-to-worker
      contacts](#343-matrix-c-consumer-to-worker-contacts)
  - [3.5 Social distancing](#35-social-distancing)
  - [3.6 Self isolating](#36-self-isolating)
- [4 Econ model](#4-econ-model)
  - [4.1 Configurations](#41-configurations)
  - [4.2 Impact of tourism](#42-impact-of-tourism)
    - [4.2.1 Food and accommodation services
      sector](#421-food-and-accommodation-services-sector)
    - [4.2.2 Sector shrinkage as a result of the
      pandemic](#422-sector-shrinkage-as-a-result-of-the-pandemic)
    - [4.2.3 Loss of international
      tourists](#423-loss-of-international-tourists)
    - [4.2.4 Dependence on international
      tourism](#424-dependence-on-international-tourism)
  - [4.3 Remote working](#43-remote-working)
- [5 Parametric distributions](#5-parametric-distributions)
  - [5.1 Hospital capacity](#51-hospital-capacity)
  - [5.2 Labour share of GVA](#52-labour-share-of-gva)

# 1 Simulation rules

- Countries are instantiated with two random variables: the response
  time, and their importation time
- The response time is the time at which the reporting country reports
  having seen X hospital cases, where X is a random number between 1 and
  20
- The importation time is a random number between 0 and 20 days, where 0
  days would be equivalent to the spillover, or origin, country
- The simulation starts at the minimum between the response time and the
  importation time
- At the response time, the BPSV, if present, is given to people aged 65
  and older; testing begins; social distancing begins; economic
  closures, if in use, are implemented
- At the importation time, five people are moved from compartment S to
  compartment E
- If closures are being implemented, the rules in Tables
  <a href="#tab:rulesreactive">1.1</a> and
  <a href="#tab:ruleselimination">1.2</a> are followed
- The SARS-X–specific vaccine is rolled out starting on day 107 or 372
  after the response time, depending on the investment assumption
- All people aged 15 and over are eligible for vaccination, and we
  assume 80% take it up
- Distribution rate increases linearly to a maximum of 1% of the
  population per day, at which is stays until 80% coverage is reached
- When vaccine rollout is complete, closures, testing and social
  distancing end
- When the doubling time is more than 30 days and there are fewer than
  1,000 people in hospital, the simulation ends.

| From/to            | No closures                                                                                                         | Light closures                                                | Heavy closures                                          |
|:-------------------|:--------------------------------------------------------------------------------------------------------------------|:--------------------------------------------------------------|:--------------------------------------------------------|
| **No closures**    |                                                                                                                     |                                                               | t = response time OR Hospital occupancy \> 95% capacity |
| **Light closures** | (Growth rate \< 0.025 OR Hospital occupancy \< 25% capacity) AND vaccine rollout complete OR $R(D(\textbf{1}) < 1$) |                                                               | Hospital occupancy \> 95% capacity                      |
| **Heavy closures** |                                                                                                                     | Hospital occupancy \< 25% capacity AND t \> 7 + response time |                                                         |

Table 1.1: State transition rules for reactive closure strategies

| From/to            | No closures                                        | Light closures                        | Heavy closures                                          |
|:-------------------|:---------------------------------------------------|:--------------------------------------|:--------------------------------------------------------|
| **No closures**    |                                                    |                                       | t = response time OR Hospital occupancy \> 95% capacity |
| **Light closures** | Vaccine rollout complete OR $R(D(\textbf{1}) < 1$) |                                       | Rt \> 1.2                                               |
| **Heavy closures** | Vaccine rollout complete OR $R(D(\textbf{1}) < 1$) | Rt \< 0.95 AND t \> 7 + response time |                                                         |

Table 1.2: State transition rules for the elimination strategy

# 2 Socio-economic costs

We assign monetary values to YLLs and to years of education in order to
add health and education costs of mitigation strategies to the costs of
economic closures. We define the total socio-economic costs TSC of an
epidemic as the sum of the individual costs:

$$\begin{equation}
\text{TSC} = L_1\text{VLY} + L_2 + L_3\text{VSY},
\label{eq:swf}
\end{equation}$$

where $L_1$ is the number of discounted life years lost and VLY the
value of a discounted life year; $L_2$ is the lost output over the
period due to reduced economic activity; and $L_3$ is the number of
school years lost and VSY the value of one school year.

## 2.1 Lost lives

To value lives lost, we make use of the expected remaining life years
per age group (Global Burden of Disease Collaborative Network 2021).
These are used to estimate the expected number of years of life lost per
death, and to estimate the value of a life year. We map the remaining
life expectancy $l_a$ for the GBD age groups $a$ to $l_g$ for the model
age groups $g$ as a population-weighted average, taking into account the
size of each age group, $N_a$. For the expected number of life years
lost per death, we take into account also the probability to die given
infection, $P(D|I,a)$:
$$l_g^{\text{(death)}} = \frac{\sum_{a\in g}N_al_aP(D|I,a)}{\sum_{a\in g}N_aP(D|I,a)}; $$
$$l_g^{\text{(life)}} = \frac{\sum_{a\in g}N_al_a}{\sum_{a\in g}N_a}; $$

Expected life years remaining with discounting taken into account can be
written

``` math
\hat{l}_g=\sum_{y=1}^{l_g}\frac{1}{(1+r)^{y}}
```

for discount rate $r>0$. The discounted number of years lost given $D_g$
deaths due to COVID-19 for each age group is

``` math
L_1=\sum_gD_g\hat{l}_g^{\text{(death)}}.
```

The VLY used by policy makers should reflect the value that members of
the society place on reductions of their own mortality. We rely on the
intrinsic rather than instrumental interpretation of the valuation of
life (Cutler and Summers 2020), and we use existing estimates of the
value of a statistical life (VSL) to estimate VLY. We interpret the VSL
as a population-weighted average (Ananthapavan et al. 2021; Robinson,
Sullivan, and Shogren 2021), where each age group has a VSL defined by
the number of expected life years remaining, and where each discounted
year has the same value:

$$\begin{equation}
\text{VSL}=\frac{\sum_gN_g\hat{l}_g^{\text{(life)}}}{\sum_gN_g}\text{VLY}.
\end{equation}$$

## 2.2 Lost economic output

We measure the cost of economic closures in terms of lost gross value
added (GVA): the GDP generated by an economic configuration is the
maximum GVA (denoted $z_i$ for each sector $i$) multiplied by the
respective sector openings, summed over the period. The maximum possible
GDP (which is with no closures) is $Z_0=\frac{T}{365}\sum_{i}z_i$, and
we use pre-pandemic output to define the maximum possible values.

$x_{i}(t)$ is the proportion of the workforce contributing to economic
production out of the total workforce $N_i$ on day $t$. The workforce
can be additionally depleted due to sickness, hospitalisation and death,
leaving a smaller fraction ($`\hat{x}_{i}(t)`$) to contribute to
production.

``` math
\hat{x}_{i}(t)=x_{i}(t)-\sum_{v}\left(p_3p_{17}I_{v,i}^{(A)}(t)+p_4p_{17}I_{v,i}^{(S)}(t)+H_{v,i}(t)+D_{v,i}(t)\right)/N_i
```

for vaccine status $v$, infectious and symptomatic $I_S$, hospitalised
$H$, deceased $D$, with total population $N_i$ for sector $i$. $p_3$ is
the fraction of asymptomatic infectious averted by self isolating, $p_4$
is the fraction of symptomatic infectious averted by self isolating. and
$p_{17}$ is the number of infectious periods for which individuals are
required to isolate.

Then the total GVA for the $T$-day period is:

``` math
Z = \frac{1}{365}\left(\sum_{i\neq\text{ed}}^{\mathcal{N}}\sum_{t=1}^Tz_i\hat{x}_{i}(t) + Tz_{\text{ed}}\right)
```

and the GDP loss compared to the maximum is

$$L_2=Z_0-Z.$$

All economic sectors contribute GVA according to the level they are open
for production, except for the education sector which contributes its
maximum possible monthly GVA, $z_{\text{ed}}$ per month.

## 2.3 Lost education

For the value of a year of education, we use the method of
(Psacharopoulos, Collis, and Patrinos 2021). The loss due to school
closure is

$$L_3 =  \frac{p_{14} }{365}\left( Tp_{16}w_{g_{\text{school}}} + (1-p_{16})A \right)\text{VSY}$$

where $p_{16}$ is the proportion of students affected,
$w_{g_{\text{school}}}$ is the total number of students, $p_{14}$ is the
extent and amount of time (in years) schools are closed:
$$p_{14}=\frac{1}{365}\int_{t=1}^{T}(1-x_{\text{ed}}(t))dt,$$ and $A$
represents education lost due to student sickness with COVID-19:

$$A=\int_{t=0}^T\left(p_3p_{17}I_{i_{\text{school}}}^{(A)} + p_4p_{17}I_{i_{\text{school}}}^{(S)}+H_{i_{\text{school}}}\right)dt.$$

$$\text{VSY} =  p_{12}\cdot p_{13}\cdot p_{15}.$$

$p_{12}$ is the present value of lost earnings:

$$p_{12} = \frac{1}{w_{g_{\text{school}}}}\sum_{a\in g_{\text{school}}}N_a\left( \frac{1-(1+r)^{-(n+20-a)}}{r} -  \frac{1-(1+r)^{-(20-a)}}{r}\right)$$

for discount rate $r=0.03$, number $N_a$ students currently age $a$, and
expected number of years of work $n=45$. $p_{13}$ is mean annual
earnings, $p_{15}=0.08$ is the rate of return for one year.

The value $p_{16}$ represents the ineffectiveness of remote teaching,
which we sample as a standard uniform random variable. We note that no
strong predictors of effectiveness of remote teaching have been
identified (Patrinos 2023). We assume that losses are linear in duration
of school closure, although there is not consensus even on this
(Betthäuser, Bach-Mortensen, and Engzell 2023). Important factors to
include in future work might be those relating to parental circumstances
including education level, engagement and socio-economic status
(Moscoviz and Evans 2022). However, these factors might be more
pertinent to intra- rather than international modelling.

# 3 Epi model

## 3.1 Ordinary differential equations

$$\begin{align}
\frac{dS_{i,v}}{dt} & = m_{v,i}M_{i,v} - \left( k_{1,v}(t) + \sum_{u=v+1}^{2}w_{v,u,i}(t) \right)S_{i,v} \\
\frac{dM_{i,v}}{dt} & = \sum_{u=0}^{v-1}w_{u,v,i}(t)S_{i,u} -\left( k_{1,v}(t) + m_{v,i} \right)M_{i,v} \quad (\text{for }v\in\{1,2\}) \\
\frac{dE_{i,v}}{dt} & = k_{1,v}(t)(S_{i,v}+M_{i,v-1}) - (k_2+k_4)E_{i,v} \\
\frac{dI_{i,v}^{(A)}}{dt} & = k_2E_{i,v} - k_3I_{i,v}^{(A)} \\
\frac{dI_{i,v}^{(S)}}{dt} & = k_4E_{i,v} - (k_{5,i,v}+k_{6,i,v})I_{i,v}^{(S)} \\
\frac{dR_{i,v}}{dt} & = k_3I_{i,v}^{(A)} + k_{5,i,v}I_{i,v}^{(S)} + k_{7,i}(t) H_{i,v} - \sum_{u=v+1}^{2}w_{v,u,i}(t)R_{i,v} + \sum_{u=0}^{v-1}w_{u,v,i}(t)R_{i,v-1}\\
\frac{dH_{i,v}}{dt} & = k_{6,i,v}I_{i,v}^{(S)} - (k_{7,i}(t) + k_{8,i}(t)) H_{i,v} \\
\frac{dD_{i,v}}{dt} & =  k_{8,i}(t) H_{i,v}
\end{align}$$

## 3.2 Disease state transitions

<figure>
<img src="README_files/figure-gfm/statetransitions-1.png"
alt="Figure 3.1: Disease state transitions. S: susceptible. E: exposed. I^{(A)}: asymptomatic infectious. I^{(S)}: symptomatic infectious. H: hospitalised. R: recovered. D: died. i: stratum. v: vaccination status." />
<figcaption aria-hidden="true">Figure 3.1: Disease state transitions.
<span class="math inline"><em>S</em></span>: susceptible. <span
class="math inline"><em>E</em></span>: exposed. <span
class="math inline"><em>I</em><sup>(<em>A</em>)</sup></span>:
asymptomatic infectious. <span
class="math inline"><em>I</em><sup>(<em>S</em>)</sup></span>:
symptomatic infectious. <span class="math inline"><em>H</em></span>:
hospitalised. <span class="math inline"><em>R</em></span>: recovered.
<span class="math inline"><em>D</em></span>: died. <span
class="math inline"><em>i</em></span>: stratum. <span
class="math inline"><em>v</em></span>: vaccination status.</figcaption>
</figure>

Possible transitions between disease states are shown in Figure
<a href="#fig:statetransitions">3.1</a>. Transition rates are functions
of time $t$, vaccination status $v$, and group identity $g$ (where the
groups are the 45 sectors and the four age groups).

The rate of infection of susceptible individuals, $k_{1,v}(t)$, is
defined as

$$\begin{equation}
k_{1,v}(t) = \eta_{A,v}\rho(t)\beta\left(D(x)\cdot I^{(eff)}(t)\right)
\qquad(3.1)
\end{equation}$$

with

``` math
 I^{(eff)}(t)=\sum_{v=0}^2(\epsilon (1-p_3(t))I_{v}^{(A)}(t)+(1-p_4(t))I_{v}^{(S)}(t)). 
```

Here, $\eta_{A,v}$ is the relative probability to be infected given
vaccine status $v$; $\rho(t)$ is the time-dependent modifier of the rate
of infection, $\beta$, which captures the impact of social distancing;
$D(x)$ is the contact matrix between groups and depends on the economic
configuration $x$; $\epsilon$ is the reduction in infectiousness from
asymptomatic relative to symptomatic individuals; $p_3$ and $p_4$ are
the proportions of asymptomatic and symptomatic infectiousness averted,
respectively, due to self isolating; and $I_{\cdot,\cdot}$ is the vector
of number of infectious asymptomatic ($I_{\cdot}^{(A)}$) and symptomatic
($I_{\cdot}^{(S)}$) people who are unvaccinated ($I_{0}^{(\cdot)}$),
vaccinated with the BPSV ($I_{1}^{(\cdot)}$), or vaccinated with the
specific vaccine ($I_{2}^{(\cdot)}$).

``` math
 k_2 = (1-p_S)/\sigma 
```

is the rate to asymptomatic infectiousness, where $p_S$ is the
probability to become symptomatic, and $\sigma$ is the expected duration
of the latent period before the onset of infectiousness;

``` math
 k_3 = 1/\gamma_A  
```

is the rate of recovery from asymptomatic infection;

``` math
 k_4 = p_S/ \sigma; 
```

is the rate of symptom onset;

``` math
k_{5,i,v} =  (1-p_{H,i,v}) / \gamma_{I,i,v}
```

is the rate of recovery from symptomatic infection, where $p_{H,i,v}$ is
the probability to be hospitalised, and
$\gamma_{I,i,v} = p_{H,i,v}\gamma_H + (1-p_{H,i,v})\gamma_R$ is the
expected time to be in compartment $I^{(S)}$: $\gamma_H$ is the expected
duration before hospitalisation and $\gamma_R$ is the expected duration
before recovery.

``` math
p_{H,i,v}=\eta_{H,v}\hat{p}_{H,i}
```

is the baseline probability to be hospitalised ($`\hat{p}_{H,i}`$)
adjusted by the vaccine effect protecting against hospitalisation
($`\eta_{H,v}`$). Then

``` math
k_{6,i,v} = p_{H,i,v}/\gamma_{I,i,v}
```

is the rate of hospitalisation following symptomatic infection.

``` math
k_{7,i}(t) = (1-p_{D,i}(t)) / \lambda_{H,i}(t)
```

is the rate of recovery of hospitalised patients, where
$`p_{D,i}(t)=\hat{p}_{D,i}f_H(t)`$ is the baseline probability to die
given hospitalisation, adjusted by a factor encoding the increase in
fatality rate as hospital occupancy increases,
$`f_H(t)=\max\{1,1+1.87(H(t)-H_{\text{max}})/H_{\text{max}}\}`$.
$\lambda_H(i,t) = p_D(i,t)\lambda_D + (1-p_{D,i}(t))\lambda_R$ is the
expected time to be in compartment $H$: $\lambda_D$ is the expected
duration before death and $\lambda_R$ is the expected duration before
recovery. Finally,

``` math
k_{8,i}(t) = p_{D,i}(t)/\lambda_{H,i}(t)
```

is the rate of death following hospitalisation.

## 3.3 Vaccination state transitions

In our model, $v=0$ refers to unvaccinated people, $v=1$ to people who
have received a full schedule of BPSV, and $v=2$ to people who have
received a full schedule of the specific vaccine. How we model
transitions between vaccination states is shown in Figure
<a href="#fig:vaccinetransitions">3.2</a>.

$w_{0,1,i}(t)$ represents the rates of BPSV vaccination of unvaccinated
susceptible and recovered people, and $w_{1,2,i}(t)$ represents the
rates of vaccinating BPSV-vaccinated susceptible and recovered people.
$w_{0,2,i}(t)$ represents the rates of vaccinating people directly with
the specific vaccine. $m_{1}$ and $m_{2}$ are the rates of
seroconversion to vaccine-induced immunity, and $k_{12}(t)=k_1(0,t)$ and
$k_{19}(t)=k_1(1,t)$ are the rates of infection of just-vaccinated
people, which returns them to the epidemiological pathway of the lower
vaccination level.

<figure>
<img src="README_files/figure-gfm/vaccinetransitions-1.png"
alt="Figure 3.2: Vaccine state transitions. S: susceptible. M: vaccinated but not yet protected. R: recovered. v: vaccination status." />
<figcaption aria-hidden="true">Figure 3.2: Vaccine state transitions.
<span class="math inline"><em>S</em></span>: susceptible. <span
class="math inline"><em>M</em></span>: vaccinated but not yet protected.
<span class="math inline"><em>R</em></span>: recovered. <span
class="math inline"><em>v</em></span>: vaccination status.</figcaption>
</figure>

## 3.4 Contact rates

The configuration $x$ and the proportion of workers working from home
$q$ determine the scaling of exposure to infection between different
groups for different reasons:

- Worker absence due to sector closure
- Worker absence due to working from home
- Student absence due to school closure
- Customer absence due to sector closure: impact on workers
- Customer absence due to sector closure: impact on customers

We construct contact matrix $D(x)$ as the sum of four matrices: $A(x)$
(community contacts), $B(x)$ (worker-to-worker contacts), $C(x)$
(consumer-to-worker contacts), and $\hat{C}(x)$ (worker-to-consumer
contacts). We construct peacetime matrices ($x=\textbf{1}$) beginning
with a “target matrix”, which the four matrices should add up to, which
is taken from (Walker et al. 2020). By sampling relevant values, we
decompose the whole matrix into its component parts. To incorporate
closures, each matrix is transformed independently, before they are all
added together again.

Matrix $D(\textbf{1})$ is estimated using as a basis a contact matrix
from (Walker et al. 2020). These are 16-by-16 matrices, $D^{(16)}$, for
five-year age bands $a$ up to age group 75+. We map the matrix to a
four-by-four matrix $D^{(4)}$ corresponding to the four age groups $g$
used in the DAEDALUS model, using population sizes, $\hat{P}_a$:

``` math
D_{gg'}^{(4)} = \frac{\sum_{a\in g}\hat{P}_{a}\sum_{a'\in g'}D^{(16)}_{a,a'}}{\sum_{a\in g}\hat{P}_{a}},
```

and $P_g$ to represent the population sizes of the DAEDALUS age groups,

``` math
P_g=\sum_{a\in g}\hat{P}_a.
```

We get to the matrix $D(\textbf{1})$ by broadcasting the four-by-four
matrix to the 49-by-49 one. Contacts from all groups $i$ to working
groups $j$ depend on the age group of the group ($`g(i)`$), and the
fraction of the age-population represented in group $j$, where $w_{j}$
is the number of people in group $j$:

``` math
D_{ij}(\textbf{1}) = D^{(4)}_{g(i),g(j)}\frac{w_{j}}{P_{g(j)}}
```

for $i$ and $j$ including all groups (working and non-working). Each
group $i$ contains people that belong to only one age group $g$. We
refer to the age group of the people in group $i$ as $g(i)$. Then
$P_{g(j)}$ is the number of people in the age group of group $j$, so
$P_{g(j)}=w_{j}$ for age groups 0 to 4, 5 to 19 and 65+, and
$P_{g(j)}=\sum_{j\in\{1,...,N,N+3\}}w_{j}$ for ages 20 to 64.

In setting up a country, we sample values for $D^{(16)}$ (from which we
get $`D(\textbf{1})`$). At the same time, we sample the proportion of
contacts that come from workplaces, and workplace-related contacts. From
these, we get $B(\textbf{1})$ and $C(\textbf{1})$, constructing the
matrices and normalising.

Matrix B is diagonal and $B_{ii}(\textbf{1})=0$ for $i>N$ (Haw et al.
2022). Consumer-to-worker contacts (matrix $C$) describe contacts
experienced by workers from consumers per sector. Note that
$C_{ij}(\textbf{1})=0$ for $i>N$. Matrix $\hat{C}(\textbf{1})$ is the
complement of matrix $C(\textbf{1})$, computed by multiplying through by
population, transposing, and dividing again by population.

With $D(\textbf{1})$, $C(\textbf{1})$, $B(\textbf{1})$ and
$\hat{C}(\textbf{1})$, we learn $A(\textbf{1})$.

$A$ is decomposed into its constituent parts, representing intra- and
inter-household interactions ($L$), school interactions ($S$),
hospitality interactions ($H$) and travel interactions ($T$):

``` math
A(\textbf{1})=A^{(L)} + A^{(S)}(\textbf{1}) + A^{(H)}(\textbf{1}) + A^{(T)}(\textbf{1})
```

Values for $A^{(S)}(\textbf{1})$ come from sampled values representing
the fractions of contacts that come from school. School contacts are
estimated separately in two age groups (pre-school age: 0—4; school age:
5—19): $A^{(S)}(\textbf{1})$ has entries of zero for groups $g$ not in
school, and values for $g$=0 to 4 years old and $g$=5 to 19 year olds.

Likewise, $A^{(T)}(\textbf{1})$ is also sampled as a fraction of total
contacts. $A_{ij}^{(T)}(\textbf{1})\geq 0$ for $i=1,...,N$.
$A_{ij}^{(T)}(\textbf{1})=0$ for $i>N$.

Finally, $A^{(H)}(\textbf{1})$ is sampled as a fraction of
$A(\textbf{1})- A^{(S)}(\textbf{1}) - A^{(T)}(\textbf{1})$, which leaves
$A^{(L)}$.

### 3.4.1 Matrix $A$: community contacts

We construct $A(x)$ from its constituent parts, representing intra- and
inter-household interactions ($L$), school interactions ($S$),
hospitality interactions ($H$) and travel interactions ($T$):

``` math
A(x)=A^{(L)} + A^{(S)}(x) + A^{(H)}(x) + A^{(T)}(x).
```

School contacts under $x$ are the peacetime values scaled by the extent
of closure. $x_{S}$ is the extent to which schools are open, so that the
number of contacts per person scales superlinearly with school closure.

$$\begin{equation}
A_{ii}^{(S)}(x)=x_{S}^2A_{ii}^{(S)}(\textbf{1}).
\qquad(3.2)
\end{equation}$$

Matrix $A^{(T)}$ counts contacts between working people, representing
travel. We assume that transport contacts only add to the infection risk
if the sector is open and the workers travel to and from their
workplace. Again, the value for configuration $x$ is the value for
$\textbf{1}$ scaled accordingly:

$$\begin{equation}
A_{ij}^{(T)}(x) = x_{j}(1-q_i)(1-q_j)A_{ij}^{(T)}(\textbf{1}).
\qquad(3.3)
\end{equation}$$

$q_i$ is the proportion of workers from sector $i$ working from home,
and $(1-q_i)(1-q_j)$ scales contacts between workers superlinearly to
approximate the reduced transmission between commuting workers: there
should be fewer contacts per person on average, and there should be
fewer people having these contacts.

Also in this equation, $x_{j}$ scales the numbers of contacts linearly
with respect to sector closure. At the same time, the number of people
in the compartments will be reduced by their sector closure, $x_{i}$.
This, in combination with the scaled contacts, leads to superlinear
scaling.

Matrix $A^{(H)}(x)$ gives the contacts made in the hospitality sector:

$$\begin{equation}
A^{(H)}(x) = x_{H}^2A^{(H)}(\textbf{1})
\qquad(3.4)
\end{equation}$$

The value $x_{H}$ is the workforce-weighted average extent to which the
hospitality sectors are open, so that the number of contacts per person
scales superlinearly according to closure:

``` math
x_{H} = \frac{\sum_ix_{i}w_i}{\sum_iw_i}
```

where we sum over only the hospitality sectors.

### 3.4.2 Matrix $B$: Worker-to-worker contacts

$$\begin{equation}
B_{ii}(x) = x_{i}(1-q_i)^2B_{ii}(\textbf{1}),
\qquad(3.5)
\end{equation}$$

for the $i=1,...,N$ working groups, with the number of contacts adjusted
according to at-home working ($q_i$) and sector openness ($x_{i}$). As
before, there is superlinear scaling of contacts with respect to working
from home. There is linear scaling with respect to sector closure: that
is, there are fewer contacts per person, but we do not approximate there
being fewer people having them. This is because the latter is accounted
for in the movement of people out of the group upon its closure.

$$B_{ii}(x) = x_{i}^2(1-q_i)^2B_{ii}(\textbf{1})$$

``` math
B_{ii}(x) = \hat{x}_i^2B_{ii}(\textbf{1}), \quad \hat{x}_i=\max(x_{i}-q_i,0)
```

### 3.4.3 Matrix $C$: Consumer-to-worker contacts

$$\begin{equation}
C_{ij}(x) = x_{i}(1-q_i)C_{ij}(\textbf{1}),
\qquad(3.6)
\end{equation}$$

for $j=1,...,N+3$.

Here, there is linear scaling of $C_{ij}(\textbf{1})$ with respect to
working from home, and linear scaling with respect to sector closure,
which becomes superlinear scaling for sectors as individuals are moved
out of the compartment, as with matrix $B(x)$.

## 3.5 Social distancing

We parametrise the effects of ‘social distancing’ in the model using
Google’s mobility data (Figure <a href="#fig:smoothmobility">3.3</a>).
These changes in mobility were consequences of both government mandates
and individual’s choices. As we cannot separate the two, we consider a
range of possibilities, based on the range of mobility changes observed
for a given level of stringency (Figure
<a href="#fig:mobilitydrop">3.4</a>). In our model, the mandated
economic configuration leads to a change in contacts. We associate the
reduction in contacts, which translates as a relative reduction in
transmission, with the reduction in mobility.

<figure>
<img src="README_files/figure-gfm/smoothmobility.png"
alt="Figure 3.3: Mobility trajectories in 2020 for all countries, with points showing the point at which the largest drop was observed. Trajectories are averaged over “Retail and recreation”, “Transit stations” and “Workplaces” and smoothed with a spline of 80 knots." />
<figcaption aria-hidden="true">Figure 3.3: Mobility trajectories in 2020
for all countries, with points showing the point at which the largest
drop was observed. Trajectories are averaged over “Retail and
recreation”, “Transit stations” and “Workplaces” and smoothed with a
spline of 80 knots.</figcaption>
</figure>

<figure>
<img src="README_files/figure-gfm/mobilitydrop.png"
alt="Figure 3.4: The largest drop in mobility plotted against the stringency on that date." />
<figcaption aria-hidden="true">Figure 3.4: The largest drop in mobility
plotted against the stringency on that date.</figcaption>
</figure>

- We want to write mobility as a function of mandate and some epi
  outcome, e.g. deaths: $\rho(t) = (1-p_8)f(y(t),g(t)) + p_8$ where
  $\rho(t)$ is mobility, $y$ is deaths per million, $g$ is government
  mandate, and $`0 < p_8 < 1`$ is the baseline.
- We want mobility to drop monotonically with both the mandate and the
  epi outcome: $\frac{df}{dy}<0$, $\frac{df}{dg}<0$.
- We want a maximum mobility of 1 when both the mandate and the epi
  outcome are 0: $f(0,0)=1$.
- We want mobility to approach $p_8$ when the mandate and the epi
  outcome become large: $\lim_{x\to 10^6, g\to 1}f(y,g)= 0$.
- We want to allow for the possibility of redundancy between the two
  variables: $f(0,0)/f(0,g) > f(x,0)/f(y,g)$ and
  $f(0,0)/f(y,0) > f(0,g)/f(y,g)$ for $y,g>0$.

A simple model to achieve these criteria is:
$$f(y,g) = \frac{1}{1+p_9y+p_{10}g}$$ with $p_9, p_{10}>0$.

However, we might also want a model that can be parametrised with a
distribution whose uncertainty covers the whole range of possible
eventualities. The equivalent model with compounded effects would be
$$f_1(y,g) = \frac{1}{1+p_9y}\frac{1}{1+p_{10}g}.$$ The equivalent model
with completely overlapping effects would be
$$f_2(y,g) = \frac{1}{1+\max(p_9y,p_{10}g)}.$$ Then we could include
‘model uncertainty’ via some parameter $\beta\sim\mathcal{U}(0,1)$,
defining $$f(y,g) = (f_1(y,g))^{p_{11}}(f_2(y,g))^{(1-p_{11})}.$$

<figure>
<img src="README_files/figure-gfm/mobilityfitted.png"
alt="Figure 3.5: Fit of model to data." />
<figcaption aria-hidden="true">Figure 3.5: Fit of model to
data.</figcaption>
</figure>

<figure>
<img src="README_files/figure-gfm/mobilityposterior.png"
alt="Figure 3.6: Posterior distribution for parameters p_9 and p_8." />
<figcaption aria-hidden="true">Figure 3.6: Posterior distribution for
parameters <span class="math inline"><em>p</em><sub>9</sub></span> and
<span class="math inline"><em>p</em><sub>8</sub></span>.</figcaption>
</figure>

<figure>
<img src="README_files/figure-gfm/mobilitycurves.png"
alt="Figure 3.7: Sampled curves for four levels of mitigation. Data shown as points." />
<figcaption aria-hidden="true">Figure 3.7: Sampled curves for four
levels of mitigation. Data shown as points.</figcaption>
</figure>

## 3.6 Self isolating

We assume that infectious people who know their status have a
probability $p_1\sim\mathcal(U)(0,1)$ to self isolate, starting one day
into their infectious period. We assume constant infectiousness over
time. Then the amount of infectiousness averted of symptomatic people is
$p_4=p_1(\gamma_I-\min(1,1/\gamma_I))$, who isolate due to the onset of
symptoms, which we assume happens concurrently with onset of
infectiousness. The fraction of asymptomatic cases identified by testing
is $p_2(t)$. We assume asymptomatic cases have the same probability to
self isolate and that test results are returned after one day of
infectiousness. Then the infectiousness that testing averts is
$p_3(t)=p_1p_2(t)(\gamma_A-\min(1,1/\gamma_A))$.

<!-- b0    = 2.197; -->
<!-- b1    = 0.1838; -->
<!-- b2    = -1.024; -->
<!-- frac_cases_found = 1./(1+exp(b0+b1*Ip+b2*log10(trate))); -->
<!-- frac_cases_found(Ip >= trate) = min(frac_cases_found(Ip >= trate),trate/10^5); -->
<!-- frac_cases_found = max(frac_cases_found, trate/10^5 ); -->

# 4 Econ model

## 4.1 Configurations

|                                                           Sector                                                           | Lockdown | Elimination | Lockdown | Economic Closures | Lockdown (School Closures) | School Closures |
|:--------------------------------------------------------------------------------------------------------------------------:|:--------:|:-----------:|:--------:|:-----------------:|:--------------------------:|:---------------:|
|                                               Agriculture, hunting, forestry                                               |    86    |     100     |    86    |        88         |            100             |       100       |
|                                                  Fishing and aquaculture                                                   |    86    |     100     |    86    |        88         |            100             |       100       |
|                                      Mining and quarrying, energy producing products                                       |    90    |     100     |    90    |        91         |             67             |       79        |
|                                    Mining and quarrying, non-energy producing products                                     |    90    |     100     |    90    |        91         |            100             |       100       |
|                                             Mining support service activities                                              |    90    |     100     |    90    |        91         |            100             |       100       |
|                                            Food products, beverages and tobacco                                            |    70    |     100     |    70    |        94         |            100             |       100       |
|                                      Textiles, textile products, leather and footwear                                      |    70    |     98      |    70    |        94         |             89             |       92        |
|                                             Wood and products of wood and cork                                             |    70    |     98      |    70    |        94         |            100             |       95        |
|                                                Paper products and printing                                                 |    70    |     98      |    70    |        94         |            100             |       98        |
|                                            Coke and refined petroleum products                                             |    70    |     88      |    70    |        94         |             87             |       88        |
|                                               Chemical and chemical products                                               |    70    |     88      |    70    |        94         |            100             |       100       |
|                                 Pharmaceuticals, medicinal chemical and botanical products                                 |    70    |     88      |    70    |        94         |            100             |       100       |
|                                                Rubber and plastics products                                                |    70    |     88      |    70    |        94         |             87             |       100       |
|                                            Other non-metallic mineral products                                             |    70    |     88      |    70    |        94         |             92             |       89        |
|                                                        Basic metals                                                        |    70    |     100     |    70    |        94         |            100             |       100       |
|                                                 Fabricated metal products                                                  |    70    |     100     |    70    |        94         |             90             |       100       |
|                                         Computer, electronic and optical equipment                                         |    70    |     100     |    70    |        94         |             90             |       100       |
|                                                    Electrical equipment                                                    |    70    |     100     |    70    |        94         |             90             |       100       |
|                                                Machinery and equipment, nec                                                |    70    |     100     |    70    |        94         |             89             |       95        |
|                                         Motor vehicles, trailers and semi-trailers                                         |    70    |     100     |    70    |        94         |             66             |       82        |
|                                                 Other transport equipment                                                  |    70    |     100     |    70    |        94         |             66             |       82        |
|                           Manufacturing nec; repair and installation of machinery and equipment                            |    70    |     98      |    70    |        94         |             98             |       100       |
|                                    Electricity, gas, steam and air conditioning supply                                     |    89    |     97      |    89    |        100        |             94             |       94        |
|                            Water supply; sewerage, waste management and remediation activities                             |    92    |     97      |    92    |        98         |            100             |       100       |
|                                                        Construction                                                        |    56    |     94      |    56    |        92         |             95             |       95        |
|                                    Wholesale and retail trade; repair of motor vehicles                                    |    64    |     100     |    64    |        100        |             92             |       97        |
|                                         Land transport and transport via pipelines                                         |    63    |     100     |    63    |        82         |             83             |       100       |
|                                                      Water transport                                                       |    63    |     100     |    63    |        82         |             81             |       98        |
|                                                       Air transport                                                        |    63    |     18      |    63    |        82         |             16             |       42        |
|                                   Warehousing and support activities for transportation                                    |    63    |     91      |    63    |        82         |             64             |       91        |
|                                               Postal and courier activities                                                |    63    |     91      |    63    |        82         |             64             |       91        |
|                                         Accommodation and food service activities                                          |    10    |     92      |    10    |        85         |             77             |       91        |
|                                    Publishing, audiovisual and broadcasting activities                                     |    88    |     100     |    88    |        91         |            100             |       100       |
|                                                     Telecommunications                                                     |    88    |     100     |    88    |        91         |            100             |       100       |
|                                             IT and other information services                                              |    88    |     100     |    88    |        91         |            100             |       100       |
|                                             Financial and insurance activities                                             |    94    |     100     |    94    |        96         |            100             |       100       |
|                                                   Real estate activities                                                   |    98    |     100     |    98    |        98         |            100             |       100       |
|                                     Professional, scientific and technical activities                                      |    85    |     100     |    85    |        92         |             90             |       95        |
|                                            Administrative and support services                                             |    66    |     90      |    66    |        80         |             90             |       95        |
|                               Public administration and defence; compulsory social security                                |   100    |     100     |   100    |        100        |             96             |       100       |
|                                                         Education                                                          |    10    |     100     |    10    |        100        |             10             |       10        |
|                                          Human health and social work activities                                           |    75    |     100     |    75    |        92         |            100             |       100       |
|                                             Arts, entertainment and recreation                                             |    55    |     94      |    55    |        71         |             90             |       96        |
|                                                  Other service activities                                                  |    54    |     94      |    54    |        83         |             90             |       96        |
| Activities of households as employers; undifferentiated goods- and services-producing activities of households for own use |    49    |     94      |    49    |        53         |             90             |       96        |

Economic configurations used to implement strategies. Values are the
openness of the sector expressed as a percentage. Elimination values are
taken from Australia. Lockdown and Economic Closures values are taken
from the UK. School Closures values are taken from Indonesia.

## 4.2 Impact of tourism

### 4.2.1 Food and accommodation services sector

As there is no “tourism” sector in the 45-sector classification we are
using, to model the impact of changes to tourism, we identify the “Food
and accommodation services” sector with tourism. This is imperfect. The
correlation of their % contributions to GDP is 0.64 and the order of
magnitude is similar (1 to 7% vs 2 to 10% of GDP). The other two sectors
considered (Air transport and Arts, entertainment and recreation) have
little correlation with tourism in terms of % of GDP. (See Figure
<a href="#fig:pairs"><strong>??</strong></a>.)

<img src="README_files/figure-gfm/pairs-1.png" title="Correlations between tourism-related data. First: https://www.unwto.org/tourism-statistics/key-tourism-statistics. Second to fourth: https://www.unwto.org/tourism-data/international-tourism-and-covid-19. Fifth to seventh: OECD." alt="Correlations between tourism-related data. First: https://www.unwto.org/tourism-statistics/key-tourism-statistics. Second to fourth: https://www.unwto.org/tourism-data/international-tourism-and-covid-19. Fifth to seventh: OECD." style="display: block; margin: auto;" />

### 4.2.2 Sector shrinkage as a result of the pandemic

For many countries, tourism was reduced in the COVID-19 pandemic not
because of domestic mandates but because of reduced international
travel. Therefore, the fraction of tourism that comes from abroad is a
factor that can determine the impact of a pandemic on a country’s GDP
potentially independently of what happens within the country. (A useful
model extension would be to include some dependence on country factors,
e.g. case numbers.)

We model mitigation via business closures, which are mandated by sector.
We represent openness with values $x$ which range from 0 to 1, 1
representing maximum openness. To capture the impact of reduced
international travel, we set the maximum openness of the food and
accommodation services sector to be limited by international tourism as:

``` math
x = \min\{\hat{x}, 1+ y(z-1)\}
```

where $`\hat{x}`$ is the openness of the sector according to the
schedule (i.e. the mitigation strategy), $y$ is the proportion of
tourism that is international, and $z$ is the fraction international
tourism reduces to as a consequence of the pandemic. I.e. the tourism
remaining is the domestic ($1-y$) plus that that comes in from abroad
($yz$).

Therefore, the contribution of the GVA of the food and accommodation
services sector is limited either by the pandemic, or by the mitigation
measures - whichever is lower.

### 4.2.3 Loss of international tourists

We model the distribution of $z$ using data from 2020 (Figure
<a href="#fig:tourismhist"><strong>??</strong></a>, bottom-right plot).
We fit to it a log-normal distribution, and find mean value -1.39 and
standard deviation 0.39 (Figure
<a href="#fig:ytd"><strong>??</strong></a>). We use these values as
inputs for all country models.

<img src="README_files/figure-gfm/tourismhist-1.png" title="Distributions of tourism-related data from https://www.unwto.org/tourism-data/international-tourism-and-covid-19. In grey are the subset of countries for which we have GVA data by sector." alt="Distributions of tourism-related data from https://www.unwto.org/tourism-data/international-tourism-and-covid-19. In grey are the subset of countries for which we have GVA data by sector." style="display: block; margin: auto;" />

<img src="README_files/figure-gfm/ytd-1.png" title="Fit of log-normal distribution to loss-of-tourism data." alt="Fit of log-normal distribution to loss-of-tourism data." style="display: block; margin: auto;" />

### 4.2.4 Dependence on international tourism

We model $y$ as a function of the share of GDP that comes from the
sector. Note that the data we have for this are biased towards
high-income countries.

We write

$$y\sim\text{Beta}(\alpha(u),\beta(u))$$

where $u$ is the fraction of GDP coming from the Food and accommodation
sector. We learn three parameters $p_5$, $p_6$ and $p_7$ to best fit the
relationship between $u$ and $y$ in countries we have observations for:

$$p_5 = \alpha(u)+\beta(u)$$

$$p_6u + p_7 = \frac{\alpha(u)}{\alpha(u)+\beta(u)}$$

Here, $p_5$ controls the variance of the distribution and $p_6$ and
$p_7$ the linear relationship between $u$ and $y$. Using an optimisation
routine in R we find $p_5=5.93$, $p_6=3.66$ and $p_7=0.099$. Results are
shown in Figure <a href="#fig:sectortourism">4.1</a>. We use these
values as inputs for all country models.

<figure>
<img src="figures/sectortourism.png" style="width:60.0%"
alt="Figure 4.1: Predicting the percentage of tourism that comes from abroad as a function of the size of the sector. Each row represents a beta distribution whose mean is determined by the size of the sector (u). Blue points show the data we have available (grey bars in Figure ??)." />
<figcaption aria-hidden="true">Figure 4.1: Predicting the percentage of
tourism that comes from abroad as a function of the size of the sector.
Each row represents a beta distribution whose mean is determined by the
size of the sector (u). Blue points show the data we have available
(grey bars in Figure
<a href="#fig:tourismhist"><strong>??</strong></a>).</figcaption>
</figure>

## 4.3 Remote working

For each sector in each country, we have the 90% interval for the
proportion of people who can work from home from (Gottlieb et al. 2021).
We assume that the value we sample within the range is related to
internet infrastructure, so that a low value in one sector implies low
values in all sectors. We:

- take the subset of countries in the income group (LLMIC / UMIC / HIC);
- take the minimum of the lower bounds by sector (5%);
- take the maximum of the upper bounds by sector (95%);
- sample from a uniform distribution between these bounds, taking the
  same quantile for each sector.

<!-- We model the Figure <a href="#fig:internet"><strong>??</strong></a> values with Beta distributions. For LLMICs, we have parameters 1.78 and  3.11. For UMICs, we have parameters 14.32 and  6.44. For HICs, we have parameters 9.57 and  1.39. -->

# 5 Parametric distributions

|            Parameter            | Income group | Distribution | Parameter 1 | Parameter 2 |
|:-------------------------------:|--------------|:------------:|-------------|-------------|
|        internet coverage        | LLMIC        |     Beta     | 1.78        | 3.11        |
|        internet coverage        | UMIC         |     Beta     | 14.32       | 6.44        |
|        internet coverage        | HIC          |     Beta     | 9.57        | 1.39        |
| remaining international tourism | all          |  Log normal  | -1.39       | 0.39        |
|       Labour share of GVA       | LLMIC        |     Beta     | 5.09        | 4.51        |
|       Labour share of GVA       | UMIC         |     Beta     | 7.06        | 8.18        |
|       Labour share of GVA       | HIC          |     Beta     | 7.97        | 6.87        |
|        Hospital capacity        | LLMIC        |    Gamma     | 1.3         | 20.2        |
|        Hospital capacity        | UMIC         |    Gamma     | 1.73        | 40.73       |
|        Hospital capacity        | HIC          |    Gamma     | 2.05        | 46.57       |
|    Public transport fraction    | LLMIC        |     Beta     | 4.88        | 3.65        |
|    Public transport fraction    | UMIC         |     Beta     | 2.06        | 2.59        |
|    Public transport fraction    | HIC          |     Beta     | 3.23        | 11.65       |
|    Nursery contacts fraction    | LLMIC        |     Beta     | 1.35        | 1.56        |
|    Nursery contacts fraction    | UMIC         |     Beta     | 1.51        | 1.21        |
|    Nursery contacts fraction    | HIC          |     Beta     | 4.31        | 2.82        |
|    School contacts fraction     | LLMIC        |     Beta     | 3.87        | 2.22        |
|    School contacts fraction     | UMIC         |     Beta     | 8.23        | 5.77        |
|    School contacts fraction     | HIC          |     Beta     | 7.63        | 3.75        |
|          tourism P1+P2          | all          |      NA      | 6.73        | NA          |
|    Tourism to international     | all          |      NA      | 4.14        | 0.05        |

Parameter distributions.

## 5.1 Hospital capacity

<figure>
<img src="README_files/figure-gfm/hmax-1.png"
alt="Figure 4.2: Hospital capacity: available beds minus usual occupancy." />
<figcaption aria-hidden="true">Figure 4.2: Hospital capacity: available
beds minus usual occupancy.</figcaption>
</figure>

We model these values with gamma distributions. For LLMICs, we have
parameters 1.3 and 0.05. For UMICs, we have parameters 1.73 and 0.02.
For HICs, we have parameters 2.05 and 0.02. (Data sources: World Bank
(beds); OECD, WHO euro (bed occupancy rates).)

## 5.2 Labour share of GVA

We estimate the average annual income per working-age adult as the total
GVA multiplied by the fraction of GVA that goes to labour divided by the
number of working-age adults. For the fraction of GVA that goes to
labour we use PWT estimates from 2011 (Figure
<a href="#fig:labsh">4.3</a>).

<!-- For the value of a year of education, we use results from [@Psacharopoulos2021a]. For an LIC, the cost of a lost school year is 207% of GDP. For a UMIC, the cost of a lost school year is 73% of GDP. For an HIC, the cost of a lost school year is 30% of GDP. -->

<figure>
<img src="README_files/figure-gfm/labsh-1.png"
alt="Figure 4.3: Fraction of GVA that goes to labour (PWT, 2011)." />
<figcaption aria-hidden="true">Figure 4.3: Fraction of GVA that goes to
labour (PWT, 2011).</figcaption>
</figure>

We model these values with Beta distributions. For LLMICs, we have
parameters 5.09 and 4.51. For UMICs, we have parameters 7.06 and 8.18.
For HICs, we have parameters 7.97 and 6.87.

<div id="refs" class="references csl-bib-body hanging-indent">

<div id="ref-Ananthapavan2021" class="csl-entry">

Ananthapavan, Jaithri, Marj Moodie, Andrew J. Milat, and Rob Carter.
2021. “<span class="nocase">Systematic review to update ‘value of a
statistical life’ estimates for Australia</span>.” *International
Journal of Environmental Research and Public Health* 18 (11).
<https://doi.org/10.3390/ijerph18116168>.

</div>

<div id="ref-Betthauser2023" class="csl-entry">

Betthäuser, Bastian A, Anders M Bach-Mortensen, and Per Engzell. 2023.
“<span class="nocase">A systematic review and meta-analysis of the
evidence on learning during the COVID-19 pandemic</span>.” *Nature Human
Behaviour* 7 (March). <https://doi.org/10.1038/s41562-022-01506-4>.

</div>

<div id="ref-Cutler2020" class="csl-entry">

Cutler, David M., and Lawrence H. Summers. 2020.
“<span class="nocase">The COVID-19 pandemic and the \$16 trillion
virus</span>.” *JAMA* 324 (15). <https://doi.org/10.1257/pol.20170046>.

</div>

<div id="ref-GlobalBurdenofDiseaseCollaborativeNetwork2021"
class="csl-entry">

Global Burden of Disease Collaborative Network. 2021.
“<span class="nocase">Global Burden of Disease Study 2019 (GBD 2019)
Reference Life Table</span>.” Seattle, United States of America:
Institute for Health Metrics; Evaluation (IHME).

</div>

<div id="ref-Gottlieb2021" class="csl-entry">

Gottlieb, Charles, Jan Grobovšek, Markus Poschke, and Fernando Saltiel.
2021. “<span class="nocase">Working from home in developing
countries</span>.” *European Economic Review* 133: 103679.
<https://doi.org/10.1016/j.euroecorev.2021.103679>.

</div>

<div id="ref-Haw2020" class="csl-entry">

Haw, David, Giovanni Forchini, Patrick Doohan, Paula Christen, Matteo
Pianella, Rob Johnson, Sumali Bajaj, et al. 2022.
“<span class="nocase">Optimizing social and economic activity while
containing SARS-CoV-2 transmission using DAEDALUS</span>.” *Nature
Computational Science* 2: 223–33. <https://doi.org/10.25561/83928>.

</div>

<div id="ref-Moscoviz2022" class="csl-entry">

Moscoviz, Laura, and David K Evans. 2022. “<span class="nocase">Learning
loss and student dropouts during the COVID-19 pandemic: A review of the
evidence two years after schools shut down</span>.” Washington, DC:
Center for Global Development.

</div>

<div id="ref-Patrinos2023" class="csl-entry">

Patrinos, Harry Anthony. 2023. “<span class="nocase">The longer students
were out of school, the less they learned</span>.” *Journal of School
Choice* 17 (2): 161–75. <https://doi.org/10.1080/15582159.2023.2210941>.

</div>

<div id="ref-Psacharopoulos2021a" class="csl-entry">

Psacharopoulos, George, Victoria; Collis, and Patrinos. 2021.
“<span class="nocase">The COVID-19 Cost of School Closures in Earnings
and Income across the World</span>.” *Comparative Education Review* 65
(2).

</div>

<div id="ref-Robinson2021" class="csl-entry">

Robinson, Lisa A., Ryan Sullivan, and Jason F. Shogren. 2021.
“<span class="nocase">Do the benefits of COVID-19 policies exceed the
costs? Exploring uncertainties in the age–VSL relationship</span>.”
*Risk Analysis* 41 (5): 761–70. <https://doi.org/10.1111/risa.13561>.

</div>

<div id="ref-Walker2020" class="csl-entry">

Walker, Patrick G. T., Charles Whittaker, Oliver J. Watson, Marc
Baguelin, Peter Winskill, Arran Hamlet, Bimandra A. Djafaara, et al.
2020. “<span class="nocase">The impact of COVID-19 and strategies for
mitigation and suppression in low- and middle-income countries</span>.”
*Science* 369 (6502): 413–22. <https://doi.org/10.1126/science.abc0035>.

</div>

</div>
