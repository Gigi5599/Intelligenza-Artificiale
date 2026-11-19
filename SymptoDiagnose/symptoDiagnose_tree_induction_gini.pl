% Definizione del modulo `symptoDiagnose_tree_induction_gini`.
% Questo modulo contiene la definizione del predicato `induce_albero_gini/1`.
:- module(symptoDiagnose_tree_induction_gini,[induce_albero_gini/1,assicura_albero_gini/0,albero_gini/1]).

% Importazione del modulo `symptoDiagnose_training_set`.
% Questo modulo è usato per fornire i dati di allenamento
% per l'induzione dell'albero.
:- use_module(symptoDiagnose_training_set).



:- dynamic alb_gini/1.

% Predicato principale `induce_albero_gini/1`.
% Prende un parametro `Albero` che sarà l'albero di decisione indotto.
induce_albero_gini(Albero) :-
    % Raccoglie tutti gli esempi dal dataset.
    findall(e(Classe, Oggetto), e(Classe, Oggetto), Esempi),
    % Raccoglie tutti gli attributi disponibili nel dataset.
    findall(Att, a(Att, _), Attributi),
    induce_albero(Attributi, Esempi, Albero),
    % stampa_albero(Albero),
    assert(alb_gini(Albero)).


% Commenti spiegativi su come funziona `induce_albero/3`.
% Questi commenti descrivono i vari casi che possono verificarsi durante l'induzione dell'albero:
% 1. Albero = null: non ci sono esempi da analizzare.
% 2. Albero = l(Classe): tutti gli esempi appartengono alla stessa classe.
% 3. Albero = t(Attributo, [Val1:SubAlb1, Val2:SubAlb2, ...]): l'albero ha più nodi.
% 4. Albero = l(Classi): non ci sono attributi utili per ulteriore discriminazione.

% La definizione di `induce_albero/3` inizia qui.
% Caso base: se la lista degli esempi è vuota, l'albero è `null`.
induce_albero( _, [], null ) :- !.
% Caso (1) di `induce_albero/3`.
% Se tutti gli esempi appartengono alla stessa classe, restituisce un albero foglia con quella classe.
induce_albero( _, [e(Classe,_)|Esempi], l(Classe)) :-
    % Verifica che non ci siano esempi di altre classi.
    \+ (member(e(ClassX,_), Esempi), ClassX \== Classe), !.

% Caso (3) di `induce_albero/3`.
% Se gli esempi appartengono a più classi, costruisce un albero decisionale.
induce_albero( Attributi, Esempi, t(Attributo, SAlberi)) :-
    % Sceglie l'attributo migliore per discriminare le classi.
    sceglie_attributo(Attributi, Esempi, Attributo), !,
    % Rimuove l'attributo scelto dalla lista degli attributi.
    del(Attributo, Attributi, Rimanenti),
    % Ottiene i valori possibili per l'attributo scelto.
    a(Attributo, Valori),
    % Induce alberi decisionali per ogni valore dell'attributo.
    induce_alberi(Attributo, Valori, Rimanenti, Esempi, SAlberi).

% Caso (4) di `induce_albero/3`.
% Se non ci sono attributi utili per discriminare ulteriormente, restituisce un albero foglia con tutte le classi rimanenti.
induce_albero(_, Esempi, l(Classi)) :-
    % Raccoglie tutte le classi rimanenti negli esempi.
    findall(Classe, member(e(Classe,_), Esempi), Classi).

% `sceglie_attributo/3`: Seleziona l'attributo che meglio discrimina le classi.
% Usa `setof` per ordinare gli attributi in base alla loro "disuguaglianza" Gini crescente.
sceglie_attributo(Attributi, Esempi, MigliorAttributo) :-
    setof(Disuguaglianza/A,
          (member(A, Attributi), disuguaglianza(Esempi, A, Disuguaglianza)),
          [_/MigliorAttributo|_]).

% `disuguaglianza/3`: Calcola la disuguaglianza Gini per un attributo.
% La disuguaglianza è calcolata sui sottoinsiemi di esempi partizionati dai valori dell'attributo.
disuguaglianza(Esempi, Attributo, Dis) :-
    a(Attributo, AttVals),
    somma_pesata(Esempi, Attributo, AttVals, 0, Dis).

% `somma_pesata/5`: Calcola la somma pesata delle disuguaglianze Gini.
% Gini = somma su tutti i valori v di P(v) * somma su tutte le coppie i, j di P(i|v)*P(j|v).
somma_pesata(_, _, [], Somma, Somma).
% Continuazione di `somma_pesata/5`.
% Calcola la somma pesata considerando gli esempi che soddisfano un dato attributo con un valore specifico.
somma_pesata( Esempi, Att, [Val|Valori], SommaParziale, Somma) :-
	length(Esempi,N),                                            % quanti sono gli esempi
	findall( C,						     % EsempiSoddisfatti: lista delle classi ..
		 (member(e(C,Desc),Esempi) , soddisfa(Desc,[Att=Val])), % .. degli esempi (con ripetizioni)..
		 EsempiSoddisfatti ),				     % .. per cui Att=Val
	length(EsempiSoddisfatti, NVal),			     % quanti sono questi esempi
	NVal > 0, !,                                                 % almeno uno!
	findall(P,			           % trova tutte le P robabilità
                (bagof(1,		           %
                       member(_,EsempiSoddisfatti),
                       L),
                 length(L,NVC),
                 P is NVC/NVal),
                ClDst),
        gini(ClDst,Gini),
	NuovaSommaParziale is SommaParziale + Gini*NVal/N,
	somma_pesata(Esempi,Att,Valori,NuovaSommaParziale,Somma)
	;
	somma_pesata(Esempi,Att,Valori,SommaParziale,Somma). % nessun esempio soddisfa Att = Val

% `gini/2` calcola l'indice Gini.
% Gini = 1 - somma dei quadrati delle probabilità per ogni classe.
gini(ListaProbabilità, Gini) :-
    somma_quadrati(ListaProbabilità, 0, SommaQuadrati),
    Gini is 1 - SommaQuadrati.

% `somma_quadrati/3` calcola la somma dei quadrati delle probabilità.
% Utilizzata per calcolare l'indice Gini.
somma_quadrati([], S, S).
somma_quadrati([P|Ps], PartS, S)  :-
    NewPartS is PartS + P * P,
    somma_quadrati(Ps, NewPartS, S).

% `induce_alberi/5`: Induce sottoalberi decisionali.
% Viene utilizzato per creare alberi decisionali per i sottoinsiemi di esempi in base ai valori degli attributi.
induce_alberi(_, [], _, _, []).  % Nessun valore, nessun sottoalbero.
induce_alberi(Att, [Val1|Valori], AttRimasti, Esempi, [Val1:Alb1|Alberi]) :-
    % Seleziona il sottoinsieme di esempi che soddisfa un determinato valore dell'attributo.
    attval_subset(Att=Val1, Esempi, SottoinsiemeEsempi),
    % Induce un albero decisionale per il sottoinsieme di esempi.
    induce_albero(AttRimasti, SottoinsiemeEsempi, Alb1),
    % Prosegue con l'induzione degli alberi per i rimanenti valori dell'attributo.
    induce_alberi(Att, Valori, AttRimasti, Esempi, Alberi).

% `attval_subset/3`: Crea un sottoinsieme di esempi che soddisfa una specifica condizione.
% Utilizzato per filtrare esempi in base a un attributo e al suo valore.
attval_subset(AttributoValore, Esempi, Sottoinsieme) :-
    findall(e(C, O),
            (member(e(C, O), Esempi), soddisfa(O, [AttributoValore])),
            Sottoinsieme).

% `soddisfa/2`: Verifica se un oggetto soddisfa una serie di condizioni (una congiunzione di attributi e valori).
soddisfa(Oggetto, Congiunzione) :-
    \+ (member(Att=Val, Congiunzione),
        member(Att=ValX, Oggetto),
        ValX \== Val).

% `del/3`: Predicato ausiliario per eliminare un elemento da una lista.
del(T, [T|C], C) :- !.
del(A, [T|C], [T|C1]) :-
    del(A, C, C1).

% Questo predicato assicura che l'albero sia disponibile
assicura_albero_gini :-
    (   albero_gia_asserito
    ->  true
    ;   induce_albero_gini(Albero),
        assert(alb_gini(Albero))
    ).

% Controlla se l'albero è già asserito
% clause(alb(Albero)), questo predicato viene utilizzato per verificare
% se esiste una clausola nel database di clausole che corrisponde al
% modello alb
%(Albero). In altre parole, controlla se un albero è stato
% asserito nel database di clausole con il predicato alb/1.
albero_gia_asserito :-
    clause(alb_gini(_), _).

% Predicato per accedere all'albero
albero_gini(Albero) :-
    clause(alb_gini(Albero), _).

% Rimuove l'albero dal database di clausole
rimuovi_albero :-
    retractall(alb_gini(_)).


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


