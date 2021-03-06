arg_alia <- readRDS(here::here("data", paste0("arg_aliaga_", Sys.Date(), ".rds")))
arg_alia <- arg_alia%>% mutate(fecha=ymd(fecha), dias =as.numeric( fecha - min(fecha))) 


arg_alia %>% 
  dplyr::select(fecha, `COVID positivos` = casos, Fallecidos=fallecidos)%>%  
  pivot_longer(-fecha, names_to = "var", values_to = "val") %>%
  group_by(var) %>% 
  mutate(new_val = val - lag(val, default = first(val-1))) %>% 
  ggplot(aes(fecha, val))+ 
  geom_point(size=2)+#geom_smooth()+
  facet_wrap(~var, scales = "free_y", ncol=1)+
  # geom_text(aes(fecha, y= 0, label=paste0("+", new_val)),
  #           size=3, check_overlap = FALSE)+
  ggrepel::geom_text_repel(data=. %>%
                             arrange(desc(val)) %>% 
                             group_by(var) %>% 
                             slice(1), 
                           aes(label=val), size = 3, 
                           position=position_nudge(0.1), hjust=1, show.legend=FALSE)+
  scale_x_date(breaks = "2 days", minor_breaks = "1 day", 
               labels=scales::date_format("%d/%m")) +
  labs(y="", x="") -> p_ARG 

ggsave(here::here("plots", "p_ARG.jpg"), width=6,height=6,units="in",dpi=150)


# Comparación de distintos modelos utilizando el criterio de Akaike (lineal y exponencial nomas)
#
mod_exp <- lm(log(casos)~ dias,data=arg_alia)
summary(mod_exp)
mod_lin <- lm(casos~ dias,data=arg_alia)
summary(mod_lin)
AIC(mod_lin, mod_exp)

# Ajuste no-lineal del los parametros del modelo exponencial
#
mod_exp1 <- nls(casos ~ alpha * exp(beta * dias), data =arg_alia, 
                start=list(alpha=0.6,beta=0.4))

# Ajuste del modelo logístico
require(drc)
#
# f(x) = d / (1+exp(b(x - e)))
#
mod_logis <- drm(casos ~ dias, fct=L.3() , data = arg_alia)
summary(mod_logis)

AIC(mod_exp1, mod_logis)

# Despues del dia 21 El ajuste del modelo logístico es mejor 
# En el dia 21 todavia ajustaba mejor el modelo exponencial
#

# Extraigo los coeficientes para ponerlos en el gráfico
#
model <- nls(casos ~ alpha * exp(beta * dias) , 
             data = filter(arg_alia, dias<22), 
             start=list(alpha=0.6,beta=0.4))

a <- round(coef(model)[1],2)
b <- round(coef(model)[2],2)
summary(model)
# Tiempo de duplicacion
#
tau <-  round(log(2)/b,2)

ldia <- as.numeric(ymd("2020-04-12") - min(arg_alia$fecha))
predmod <- data.frame(exponencial=predict(model, newdata=data.frame(dias=0:ldia)),
                      logistico = predict(mod_logis, newdata=data.frame(dias=0:ldia))) %>% 
  mutate(dias=0:ldia, fecha=min(arg_alia$fecha)+dias)
predmod

# Estimación de R0
# Generation time from
# https://github.com/midas-network/COVID-19/tree/master/parameter_estimates/2019_novel_coronavirus

require(R0)
mGT<-generation.time("gamma", c(5.2, 1.5))
est.R0.EG(arg_alia$new_positivos, mGT, begin = 1, end=22)

tl <- est.R0.ML(arg_alia$new_positivos, mGT, begin = 1, end=22)
# plotfit(tl)
r <- round(tl$R,2)
r0 <- round(tl$conf.int,2)

col <- viridisLite::viridis(2)
# Casos totales

devtools::source_url("https://github.com/juanchiem/R-sources/blob/master/theme_juan.R?raw=TRUE")

model_comparison <- ggplot(arg_alia, aes(x = fecha, y = casos) ) +
  geom_point() +
  geom_line(data=predmod %>% 
              pivot_longer(-(dias:fecha), names_to = "Modelo", values_to = "predicted"),
            aes(x=fecha, y = predicted, color=Modelo), size = .5) + 
  scale_color_discrete( labels = c("Exponencial (AIC = 321.6)",
                                   "Logístico (AIC = 248.3)"))+
  scale_y_log10() + 
  annotate("text", x=ymd("2020-03-16"), y=1600,label=paste("R0 =", r, "[", r0[1], ",", r0[2],"]"),size=3) + 
  annotate("text", x=ymd("2020-03-16"), y=900,label=paste("Tiempo de duplicación =", tau),size=3)+
  scale_x_date(breaks = "5 days", minor_breaks = "1 day", expand = c(0.1,0.1),
               labels=scales::date_format("%d/%m")) +
  labs(y="Infectados COVID19 (escala logaritmica)", x="") +
  theme_juan(9, "top")+
  geom_vline(xintercept = ymd("2020-03-24"), linetype=2)
model_comparison
ggsave(here::here("plots", "models_ARG.jpg"), width=6, height=4, units="in", dpi=300)


"https://raw.githubusercontent.com/lsaravia/covid19ar/master/coronavirus_ar.csv"%>%  
  read_csv(col_types = cols()) -> saravia

long <- saravia  %>% 
  mutate(fecha=ymd(fecha), dias =as.numeric( fecha - min(fecha))) %>% 
  gather(tipo,N,casos:comunitarios,importados) %>% 
  filter(tipo %in% c("contactos","importados","comunitarios")) %>% 
  mutate(N = ifelse(N==0,NA,N))

# long <- saravia %>% 
#   dplyr::select(fecha, importados, 
#                 contactos = contacto_estrecho_conglomerado, 
#                 comunitarios = transmision_comunitaria) %>% 
#   pivot_longer(-fecha, names_to="tipo_contagio", values_to = "n") %>% 
#   filter(tipo_contagio %in% c("contactos","importados","comunitarios")) %>% 
#   mutate(n = ifelse(n==0,NA,n))
# 

ggplot(long,aes(x=dias,y=N,color=tipo)) + 
  geom_point() + theme_bw() +
  scale_color_viridis_d(name="Tipo de infección") + 
  scale_y_log10() + ylab("Casos")
ggsave(here::here("plots", "tipo_infeccion_ARG.jpg"), width=6, height=4, units="in", dpi=300)

