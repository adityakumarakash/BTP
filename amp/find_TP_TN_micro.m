function [TP_micro, TN_micro] = find_TP_TN_micro(gold_db_matrix, predicted_db_matrix)

    [a b]=size(gold_db_matrix);

    %Find cumulative TP
    TP_micro=sum(sum(gold_db_matrix.*predicted_db_matrix))/sum(sum(gold_db_matrix));

    %Find cumulative TN
    c=1-gold_db_matrix;
    d=1-predicted_db_matrix;
    TN_micro=sum(sum((c.*d)))/sum(sum(c));

end