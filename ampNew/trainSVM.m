function [model] = trainSVM(ylabels, classId, feature_vect, config)

        %% On only those mentions which are true for the curr relation
        temp_reln_labels = zeros(size(ylabels,1),1);
        temp_reln_labels(ylabels==classId) = 1;       
        

        %% LibSVM Train
          params = ['-s 0 -t 2 -c ', num2str(2^config.c), ' -g ', num2str(2^config.g), ' -w1 ', num2str(config.w_1_cost),' -w0 ',num2str(config.w_0_cost)]
          model = svmtrain(temp_reln_labels, feature_vect, params);

end