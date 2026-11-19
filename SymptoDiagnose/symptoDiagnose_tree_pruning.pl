:- module(symptoDiagnose_tree_pruning,[potatura_albero_gini/1,potatura_albero_entropia/1]).
:- use_module(symptoDiagnose_tree_induction_gini).
:- use_module(symptoDiagnose_tree_induction_entropy).

% La potatura di un albero decisionale un processo che cerca di
% semplificare l'albero rimuovendo alcune delle sue parti in modo da
% migliorare le prestazioni del modello o evitare l'overfitting. La
% potatura pu essere fatta in diversi modi, ma uno dei metodi comuni la
% potatura post-pruning.
potatura_albero_gini(AlberoPotato) :-
    assicura_albero_gini,
    albero_gini(Albero),
    potatura_albero_null(Albero,AlberoPotato).
    %stampa_albero(AlberoPotato).

potatura_albero_entropia(AlberoPotato) :-
    assicura_albero_entropia,
    albero_entropia(Albero),
    potatura_albero_null(Albero,AlberoPotato).
    %stampa_albero(AlberoPotato).

% potatura_albero_null(+Albero, -AlberoPotato)
% Pota i nodi dell'albero con valore 'null'
potatura_albero_null(null, null) :- !.
potatura_albero_null(t(Attributo, Sottoalberi), Risultato) :-
    potatura_sottoalberi_null(Sottoalberi, SottoalberiPotati),
    (   SottoalberiPotati = [] ->
        Risultato = null
    ;   Risultato = t(Attributo, SottoalberiPotati)
    ).
potatura_albero_null(l(Classe), l(Classe)) :- !.

% potatura_sottoalberi_null(+Sottoalberi, -SottoalberiPotati)
% Pota ciascun sottoalbero se il valore è 'null'
potatura_sottoalberi_null([], []).
potatura_sottoalberi_null([_Valore:null|Resto], RestoPotato) :-
    !, potatura_sottoalberi_null(Resto, RestoPotato).
potatura_sottoalberi_null([Valore:Albero|Resto], [Valore:AlberoPotato|RestoPotato]) :-
    potatura_albero_null(Albero, AlberoPotato),
    potatura_sottoalberi_null(Resto, RestoPotato).



%predicato per la stampa di tutto l'albero decisionale
stampa_albero(Albero) :-
    %induce_albero(Albero),
    scrivi_albero(Albero, 0).

% Stampa un albero indentato
scrivi_albero(null, _) :-
    write(' ==> SCONOSCIUTO'), nl.

scrivi_albero(l(Classe), I) :-
    tab(I), write(' ==> '), write(Classe), nl.

scrivi_albero(t(Attributo, ListaRami), I) :-
    tab(I), write(Attributo), nl,
    I1 is I + 2,
    scrivi_rami(ListaRami, I1).

% Stampa i rami di un albero
scrivi_rami([], _).

scrivi_rami([Valore:Rametto | AltriRami], I) :-
    tab(I), write(Valore), write(':'),
    I2 is I + 2,
    scrivi_albero(Rametto, I2),
    scrivi_rami(AltriRami, I).

