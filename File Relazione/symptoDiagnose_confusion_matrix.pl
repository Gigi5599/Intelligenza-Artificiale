:- module(symptoDiagnose_confusion_matrix,[predici_classe/3]).
:- use_module(symptoDiagnose_test_set).
:- use_module(symptoDiagnose_tree_pruning).
:- use_module(symptoDiagnose_tree_induction_entropy).
:- use_module(symptoDiagnose_tree_induction_gini).

%Predizione della classe:
% Aggiungi un predicato per ottenere la classe predetta dall'albero di
% decisione prolog.
% Predice la classe di un oggetto utilizzando l'albero di decisione.
predici_classe(Albero,Descrizione, ClassePredetta) :-
    predici_classe_ricorsivo(Albero, Descrizione, ClassePredetta).

predici_classe_ricorsivo(l(Classe), _, Classe) :- !.
predici_classe_ricorsivo(t(Attributo, Rami), Descrizione, ClassePredetta) :-
    member(Attributo = Valore, Descrizione),
    member(Valore:Albero, Rami),
    predici_classe_ricorsivo(Albero, Descrizione, ClassePredetta).


% Calcola le predizioni per il test set
calcola_predizioni_test_set(Predizioni,Albero) :-
    findall(predizione(ClasseReale, ClassePredetta),
            (s(ClasseReale, Descrizione), predici_classe(Albero,Descrizione, ClassePredetta)),
            Predizioni).

% Utilizza questo predicato per stampare la matrice di confusione
% dell'albero potato gini
stampa_matrice_confusione_albero_potato_gini(MatriceConfusione,Metriche) :-
    potatura_albero_gini(AlberoPotato),
    calcola_predizioni_test_set(Predizioni,AlberoPotato),
    conta_occorrenze(Predizioni, _, MatriceConfusione),
    metriche_matrice_confusione(MatriceConfusione,Metriche).
    %stampa_matrice_confusione(MatriceConfusione, Classi).

% Utilizza questo predicato per stampare la matrice di confusione
% dell'albero potato entropia
stampa_matrice_confusione_albero_potato_entropia(MatriceConfusione,Metriche) :-
    potatura_albero_gini(AlberoPotato),
    calcola_predizioni_test_set(Predizioni,AlberoPotato),
    conta_occorrenze(Predizioni, _, MatriceConfusione),
    metriche_matrice_confusione(MatriceConfusione,Metriche).
   % stampa_matrice_confusione(MatriceConfusione, Classi).

% Utilizza questo predicato per stampare la matrice di confusione
% dell'albero gini
stampa_matrice_confusione_albero_gini(MatriceConfusione) :-
    assicura_albero_gini,
    albero_gini(Albero),
    calcola_predizioni_test_set(Predizioni,Albero),
    conta_occorrenze(Predizioni, Classi, MatriceConfusione),
    metriche_matrice_confusione(MatriceConfusione,Metriche),
    salva_matrice_confusione_e_metriche_su_file(MatriceConfusione, Classi, Metriche, 'MatriceGini.txt').

stampa_matrice_confusione_albero_entropia(MatriceConfusione) :-
    assicura_albero_entropia,
    albero_entropia(Albero),
    calcola_predizioni_test_set(Predizioni,Albero),
    conta_occorrenze(Predizioni,Classi, MatriceConfusione),
    metriche_matrice_confusione(MatriceConfusione,Metriche),
    salva_matrice_confusione_e_metriche_su_file(MatriceConfusione, Classi, Metriche, 'MatriceEntropia.txt').

% Salva la matrice di confusione e le metriche su un file
salva_matrice_confusione_e_metriche_su_file(MatriceConfusione, Classi, Metriche, NomeFile) :-
    open(NomeFile, write, Stream),
    stampa_matrice_confusione(MatriceConfusione, Classi, Stream),
    nl(Stream),
    stampa_metriche(Metriche, Stream),
    close(Stream).


% Stampa la matrice di confusione su un file stream
stampa_matrice_confusione(MatriceConfusione, Classi, Stream) :-
    % Stampa l'intestazione per le classi
    write(Stream, 'Real\\Pred\t'),
    stampa_intestazione_classi(Classi, Stream),
    nl(Stream),
    % Stampa le righe della matrice di confusione
    stampa_righe_matrice(MatriceConfusione, Classi, Stream).

% Stampa l'intestazione delle classi su un file stream
stampa_intestazione_classi([], Stream) :- nl(Stream).
stampa_intestazione_classi([Classe|RestoClassi], Stream) :-
    format(Stream, '~w\t', [Classe]),
    stampa_intestazione_classi(RestoClassi, Stream).

% Stampa le righe della matrice di confusione su un file stream
stampa_righe_matrice([], _, Stream).
stampa_righe_matrice([Riga|RestoMatrice], Classi, Stream) :-
    stampa_riga_matrice(Riga, Classi, Stream),
    nl(Stream),
    stampa_righe_matrice(RestoMatrice, Classi, Stream).

% Stampa una riga della matrice di confusione su un file stream
stampa_riga_matrice([], [], Stream).
stampa_riga_matrice([Conteggio|Riga], [Classe|RestoClassi], Stream) :-
    format(Stream, '~w\t~d\t', [Classe, Conteggio]),
    stampa_riga_matrice(Riga, RestoClassi, Stream).


% Qui assumiamo che Metriche sia una lista di strutture del tipo metrica(Index, TP, FP, FN, TN, F1)
stampa_metriche([], _).
stampa_metriche([Metrica|RestoMetriche], Stream) :-
    % Assumendo che ogni Metrica abbia la forma metrica(Index, TP, FP, FN, TN, F1)
    Metrica = metrica(Index, TP, FP, FN, TN, F1),
    format(Stream, 'Metriche per Classe ~w: TP=~d, FP=~d, FN=~d, TN=~d, F1=~f~n', [Index, TP, FP, FN, TN, F1]),
    stampa_metriche(RestoMetriche, Stream).


% Confronta le predizioni con le classi reali e conta le occorrenze
conta_occorrenze(Predizioni, Classi, MatriceConfusione) :-
    setof(Classe, ClasseReale^member(predizione(ClasseReale, Classe), Predizioni), Classi),
    conta_occorrenze_interne(Classi, Classi, Predizioni, MatriceConfusione).

conta_occorrenze_interne([], _, _, []).
conta_occorrenze_interne([ClasseReale|RestoClassi], Classi, Predizioni, [Riga|Matrice]) :-
    conta_occorrenze_riga(ClasseReale, Classi, Predizioni, Riga),
    conta_occorrenze_interne(RestoClassi, Classi, Predizioni, Matrice).

conta_occorrenze_riga(_, [], _, []).
conta_occorrenze_riga(ClasseReale, [ClassePredetta|RestoClassi], Predizioni, [Conteggio|RestoRiga]) :-
    conta_occorrenze_classe(ClasseReale, ClassePredetta, Predizioni, Conteggio),
    conta_occorrenze_riga(ClasseReale, RestoClassi, Predizioni, RestoRiga).

conta_occorrenze_classe(ClasseReale, ClassePredetta, Predizioni, Conteggio) :-
    aggregate_all(count, member(predizione(ClasseReale, ClassePredetta), Predizioni), Conteggio).


% La tua matrice di confusione con classi predette e reali è ora pronta
% Calcola TP, FP, FN e TN per tutte le classi
metriche_matrice_confusione(Matrix, Metriche) :-
    length(Matrix, NumClassi),
    metriche_matrice_confusione(Matrix, 1, NumClassi, Metriche).

metriche_matrice_confusione(_, Index, NumClassi, []) :-
    Index > NumClassi.
metriche_matrice_confusione(Matrix, Index, NumClassi, [Metrica|RestoMetriche]) :-
    metriche_per_classe(Matrix, Index, TP, FP, FN, TN, F1),
    Metrica = metrica(Index, TP, FP, FN, TN, F1),
    NextIndex is Index + 1,
    metriche_matrice_confusione(Matrix, NextIndex, NumClassi, RestoMetriche).

% Calcola TP, FP, FN, TN, F1, ClassePredetta e ClasseReale per una data classe (Index)
metriche_per_classe(Matrix, Index, TP, FP, FN, TN, F1) :-
    estrai_true_positives(Matrix, Index, TP),
    estrai_false_positives(Matrix, Index, FP),
    estrai_false_negatives(Matrix, Index, FN),
    estrai_true_negatives(Matrix, Index, TN),
    f1_score(TP, FP, FN, F1).

% Estrai i True Positives
estrai_true_positives(Matrix, Index, TP) :-
    nth1(Index, Matrix, Row),
    nth1(Index, Row, TP).

% Estrai i False Positives
estrai_false_positives(Matrix, Index, FP) :-
    findall(Elem, (nth1(I, Matrix, Row), I \= Index, nth1(Index, Row, Elem)), FPList),
    sum_list(FPList, FP).

% Estrai i False Negatives
estrai_false_negatives(Matrix, Index, FN) :-
    nth1(Index, Matrix, Row),
    findall(Elem, (nth1(J, Row, Elem), J \= Index), FNList),
    sum_list(FNList, FN).

% Estrai i True Negatives
estrai_true_negatives(Matrix, Index, TN) :-
    findall(Elem, (nth1(I, Matrix, Row), I \= Index, nth1(J, Row, Elem), J \= Index), TNList),
    sum_list(TNList, TN).

% Calcola la precisione
% TP: True Positives, FP: False Positives
calcola_precisione(TP, FP, Precisione) :-
    (TP + FP =:= 0 -> Precisione = 0; Precisione is TP / (TP + FP)).

% Calcola la recall
% TP: True Positives, FN: False Negatives
calcola_recall(TP, FN, Recall) :-
    (TP + FN =:= 0 -> Recall = 0; Recall is TP / (TP + FN)).
% Calcola lo score F1
% TP: True Positives, FP: False Positives, FN: False Negatives
f1_score(TP, FP, FN, F1) :-
    calcola_precisione(TP, FP, Precision),
    calcola_recall(TP, FN, Recall),
    (Precision + Recall =:= 0 -> F1 = 0; F1 is 2 * (Precision * Recall) / (Precision + Recall)).


