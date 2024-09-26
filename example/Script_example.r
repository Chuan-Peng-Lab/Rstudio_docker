
### Example script"

library(tidyverse)

rm(list = ls()) 

df.js <- read.csv('./example/df_example.csv') %>%
      dplyr::rename(Matchness = match,
                    Valence = valence) %>%
      dplyr::mutate(Matchness = ifelse(Matchness == 'match', 'Match', 'Mismatch'),
                    Valence = ifelse(Valence == 'good', 'Good', 
                                     ifelse(Valence == 'bad', 'Bad', 'Neutral')),
                    rt = ifelse(rt == 'null', NA, as.numeric(rt)),
                    acc = ifelse(acc == 'null', NA, as.numeric(acc)))

# 计算基本信息
df.js.basic <- df.js %>% 
      dplyr::select(subj_idx, sex, age, edu) %>% 
      dplyr::distinct(subj_idx, sex, age) %>% 
      dplyr::summarise(subj_N = length(subj_idx),
                       female_N = sum(sex == 'female'),
                       male_N = sum(sex == 'male'),
                       Age_mean = round(mean(age),2),
                       Age_sd   = round(sd(age),2)
      )

# check trials number, doubt check the data: v010001's trials number is not correct
df.js.trials <- df.js %>%
      dplyr::filter(block_type == "test") %>%
      dplyr::group_by(subj_idx, Matchness, Valence) %>%
      dplyr::summarise(n = n())
      
# Exclude participants if necessary
df.js.excld.sub <- df.js %>% 
      dplyr::filter(block_type == "test") %>%
      dplyr::group_by(subj_idx) %>%
      dplyr::summarise(meanACC = mean(acc)) %>%
      dplyr::filter(meanACC <= 0.6) %>%
      dplyr::pull(subj_idx)

num_invalid_trial <- df.js %>% 
      dplyr::filter(block_type == "test") %>%                   # exclude practice trials
      dplyr::filter(!(subj_idx %in% df.js.excld.sub)) %>%       # exclude invalid participant
      dplyr::filter(rt <= 200) %>%
      dplyr::summarise(n = n()) %>%
      dplyr::pull(n)

# ratio of invalid trials
df.js.invalid_trial_rate <- df.js %>% 
      dplyr::filter(block_type == "test") %>%                   # exclude practice trials
      dplyr::filter(!(subj_idx %in% df.js.excld.sub)) %>%   # exclude invalid participant
      dplyr::summarise(n = n()) %>%
      dplyr::mutate(ratio = num_invalid_trial/n) %>%
      dplyr::pull(ratio)

df.js.v <- df.js %>%
      dplyr::filter(block_type == "test") %>%                   # exclude practice trials
      dplyr::filter(!(subj_idx %in% df.js.excld.sub)) %>%       # exclude invalid participant
      dplyr::filter(rt >= 200)                                  # exclude very short response

df.js.v.basic <- df.js.v %>%
      dplyr::distinct(subj_idx, sex, age, edu) %>%
      dplyr::distinct(subj_idx, sex, age, .keep_all = TRUE) %>%
      dplyr::summarise(N = length(subj_idx),
                       N_female = length(sex[sex == "female"]),
                       N_male = length(sex[sex == "male"]),
                       Age_mean = round(mean(age,na.rm=TRUE),2),
                       Age_sd = round(sd(age,na.rm=TRUE),2),
                       Age_missing = sum(is.na(age)),
                       Sex_missing = sum(is.na(sex))) %>%
      dplyr::mutate(Sample = 'JsPsych')

# 计算Dprime
df.js.v.dprime <- df.js.v %>% 
      dplyr::select(subj_idx, Matchness, Valence, acc) %>%
      dplyr::mutate(
            hit = ifelse(acc == 1 & Matchness == "Match", 1, 0),    # hit
            cr = ifelse(acc == 1 & Matchness != "Match", 1, 0),     # correct rejection
            miss = ifelse(acc == 0 & Matchness == "Match", 1, 0),   # miss
            fa = ifelse(acc == 0 & Matchness != "Match", 1, 0)      # false alarm
      ) %>% 
      dplyr::group_by(
            subj_idx, Valence
      ) %>% 
      dplyr::summarise(
            # rt = mean(as.integer(rt), na.rm = T),
            hit = sum(hit),
            fa = sum(fa),
            miss = sum(miss),
            cr = sum(cr)
      ) %>% 
      dplyr::mutate(
            hitP = ifelse(hit / (hit + miss) < 1 & hit / (hit + miss) > 0, 
                          hit / (hit + miss), 
                          1 - 1/(2 * (hit + miss))),
            faP = ifelse(fa / (fa + cr) > 0 & fa / (fa + cr) < 1, 
                         fa / (fa + cr), 
                         1/(2 * (fa + cr))),
            dprime = qnorm(hitP) - qnorm(faP)
      )

# 计算分组平均RT时间
df.js.v.RT <- df.js.v %>% 
      dplyr::filter(acc == 1) %>%
      dplyr::group_by(
            subj_idx, Valence, Matchness
      ) %>% 
      dplyr::summarise(
            rt = mean(as.integer(rt), na.rm = T)
      ) %>%
      dplyr::ungroup()

# long to wide and combine
df.js.v.wide <- merge(
      reshape2::dcast(df.js.v.RT, subj_idx ~  Matchness + Valence, value.var = "rt"), 
      reshape2::dcast(df.js.v.dprime, subj_idx ~  Valence, value.var = "dprime"), 
      by.x = "subj_idx"
      ) %>%
      dplyr::rename(d_Bad = Bad,
                    d_Good = Good,
                    d_Neutral = Neutral)


# Below are the basic information of the data.
df.v.basic <- df.js.v.basic %>%
      dplyr::select(Sample, N, N_female, N_male, Age_mean, Age_sd)

print(df.v.basic)


#### We then compare the mean RT and *d* prime (calculated in signal detection theory).

# First, define a function to plot the data. We may try `raincloud` in the future.
Val_plot_NHST <- function(df.rt, df.d){
      df.plot <- df.rt %>%
            dplyr::filter(Matchness == 'Match') %>%  # select matching data for plotting only.
            dplyr::rename(RT = rt) %>%
            dplyr::full_join(., df.d) %>%  
            tidyr::pivot_longer(., cols = c(RT, dprime), 
                                names_to = 'DVs', 
                                values_to = "value") %>% # to longer format
            dplyr::mutate(Valence =factor(Valence, levels = c('Good','Neutral', 'Bad')),
                          DVs = factor(DVs, levels = c('RT', 'dprime')),
                          # create an extra column for ploting the individual data cross different conditions.
                          Conds = ifelse(Valence == 'Good', 1, 
                                         ifelse(Valence == 'Neutral', 2, 3))
            ) 
      
      df.plot$Conds_j <- jitter(df.plot$Conds, amount=.09) # add gitter to x
      
      # New facet label names for panel variable
      # https://stackoverflow.com/questions/34040376/cannot-italicize-facet-labels-with-labeller-label-parsed
      levels(df.plot$DVs ) <- c("RT"=expression(paste("Reaction ", "times (ms)")),
                                "dprime"=expression(paste(italic("d"), ' prime')))
      levels(df.plot$DVs ) <- c("RT"=expression(paste("Reaction ", "times (ms)")),
                                "dprime"=expression(paste(italic("d"), ' prime')))
      
      df.plot.sum_p <- df.plot  %>% 
            dplyr::group_by(Valence,DVs) %>%
            dplyr::summarise(mean = mean(value),
                             sd = sd(value),
                             n = n()) %>%
            dplyr::mutate(se = sd/sqrt(n)) %>%
            dplyr::rename(value = mean) %>%
            dplyr::mutate(Val_num = ifelse(Valence == 'Good', 1,
                                           ifelse(Valence == 'Neutral', 2, 3)))
      
      pd1 <- position_dodge(0.5)
      scaleFUN <- function(x) sprintf("%.2f", x)
      scales_y <- list(
            RT = scale_y_continuous(limits = c(500, 900)),
            dprime = scale_y_continuous(labels=scaleFUN)
      )
      
      p_df_sum <- df.plot  %>% # dplyr::filter(DVs== 'RT') %>%
            ggplot(., aes(x = Valence, y = value, colour = as.factor(Valence))) +
            geom_line(aes(x = Conds_j, y = value, group = subj_idx),         # link individual's points by transparent grey lines
                      linetype = 1, size = 0.8, colour = "#000000", alpha = 0.06) + 
            geom_point(aes(x = Conds_j, y = value, group = subj_idx),   # plot individual points
                       colour = "#000000",
                       size = 3, shape = 20, alpha = 0.1) +
            geom_line(data = df.plot.sum_p, aes(x = as.numeric(Valence), # plot the group means  
                                                y = value, 
                                                #group = Identity, 
                                                colour = as.factor(Valence),
            ), 
            linetype = 1, position = pd1, size = 2)+
            geom_point(data = df.plot.sum_p, aes(x = as.numeric(Valence), # group mean
                                                 y = value, 
                                                 #group = Identity, 
                                                 colour = as.factor(Valence),
            ), 
            shape = 18, position = pd1, size = 5) +
            geom_errorbar(data = df.plot.sum_p, aes(x = as.numeric(Valence),  # group error bar.
                                                    y = value, # group = Identity, 
                                                    colour = as.factor(Valence),
                                                    ymin = value- 1.96*se, 
                                                    ymax = value+ 1.96*se), 
                          width = .05, position = pd1, size = 2, alpha = 0.75) +
            scale_colour_brewer(palette = "Dark2") +
            scale_x_continuous(breaks=c(1, 2, 3),
                               labels=c("Good", "Neutral", "Bad")) +
            scale_fill_brewer(palette = "Dark2") +
            #ggtitle("A. Matching task") +
            theme_bw()+
            theme(panel.grid.major = element_blank(),
                  panel.grid.minor = element_blank(),
                  panel.background = element_blank(),
                  panel.border = element_blank(),
                  text=element_text(family='Times'),
                  legend.title=element_blank(),
                  #legend.text = element_text(size =6),
                  legend.text = element_blank(),
                  legend.position = 'none',
                  plot.title = element_text(lineheight=.8, face="bold", size = 16, margin=margin(0,0,20,0)),
                  axis.text = element_text (size = 14, color = 'black'),
                  axis.title = element_text (size = 14),
                  axis.title.x = element_blank(),
                  axis.title.y = element_blank(),
                  axis.line.x = element_line(color='black', size = 1),    # increase the size of font
                  axis.line.y = element_line(color='black', size = 1),    # increase the size of font
                  strip.text = element_text (size = 15, color = 'black'),  # size of text in strips, face = "bold"
                  panel.spacing = unit(1.5, "lines")
            ) +
            facet_wrap( ~ DVs,
                        scales = "free_y", nrow = 1,
                        labeller = label_parsed)
      return(p_df_sum)
}


# Then, plot the data from both samples.

p_js <- Val_plot_NHST(df.js.v.RT, df.js.v.dprime)
p_js <- p_js + 
  ggtitle('Social Associative Learning Task data, collected online (jsPsych)')

p_js