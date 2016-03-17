function [F] = findFScoreMicro(config, TP, TN, Theta)

        F = ((1+config.BETA^2)*TP)/(config.BETA^2+Theta+TP-Theta*TN);

end

