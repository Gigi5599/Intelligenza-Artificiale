:- module(symptoDiagnose_tree_induction_entropy,[induce_albero_entropia/1,assicura_albero_entropia/0,albero_entropia/1]).
:- use_module(symptoDiagnose_training_set).
:- dynamic alb_entropy/1.


% entropia(+Probabilità, -Entropia)
entropia(Probabilità, Entropia) :-
    findall(-P * log(P), (member(P, Probabilità), P > 0), Logs),
    sum_list(Logs, Entropia).

% gini(ListaProbabilità, Gini)
% La funzione è stata rinominata in entropia_ponderata per mantenere la coerenza
entropia_ponderata(ListaProbabilità, Entropia) :-
    entropia(ListaProbabilità, Entropia).



induce_albero_entropia( Albero ) :-
	findall( e(Classe,Oggetto), e(Classe,Oggetto), Esempi),
        findall( Att,a(Att,_), Attributi),
        induce_albero( Attributi, Esempi, Albero),
        %stampa_albero(Albero),
        assert(alb_entropy(Albero)).

% induce_albero( +Attributi, +Esempi, -Albero):
% l'Albero indotto dipende da questi tre casi:
% (1) Albero = null: l'insieme degli esempi è vuoto
% (2) Albero = l(Classe): tutti gli esempi sono della stessa classe
% (3) Albero = t(Attributo, [Val1:SubAlb1, Val2:SubAlb2, ...]):
%     gli esempi appartengono a più di una classe
%     Attributo è la radice dell'albero
%     Val1, Val2, ... sono i possibili valori di Attributo
%     SubAlb1, SubAlb2,... sono i corrispondenti sottoalberi di
%     decisione.
% (4) Albero = l(Classi): non abbiamo Attributi utili per
%     discriminare ulteriormente
induce_albero( _, [], null ) :- !.			         % (1)
induce_albero( _, [e(Classe,_)|Esempi], l(Classe)) :-	         % (2)
	\+ ( member(e(ClassX,_),Esempi), ClassX \== Classe ),!.  % no esempi di altre classi (OK!)
induce_albero( Attributi, Esempi, t(Attributo,SAlberi) ) :-	 % (3)
	sceglie_attributo( Attributi, Esempi, Attributo), !,     % implementa la politica di scelta
	del( Attributo, Attributi, Rimanenti ),			 % elimina Attributo scelto
	a( Attributo, Valori ),					 % ne preleva i valori
	induce_alberi( Attributo, Valori, Rimanenti, Esempi, SAlberi).
induce_albero( _, Esempi, l(Classi)) :-                          % finiti gli attributi utili (KO!)
	findall( Classe, member(e(Classe,_),Esempi), Classi).

% sceglie_attributo( +Attributi, +Esempi, -MigliorAttributo):
% seleziona l'Attributo che meglio discrimina le classi; si basa sul
% concetto della "Gini-disuguaglianza"; utilizza il setof per ordinare
% gli attributi in base al valore crescente della loro disuguaglianza
sceglie_attributo( Attributi, Esempi, MigliorAttributo )  :-
	setof( Disuguaglianza/A,
	      (member(A,Attributi) , disuguaglianza(Esempi,A,Disuguaglianza)),
	      [_/MigliorAttributo|_] ).

% disuguaglianza(+Esempi, +Attributo, -Dis):
% Dis è la disuguaglianza combinata dei sottoinsiemi degli esempi
% partizionati dai valori dell'Attributo
disuguaglianza( Esempi, Attributo, Dis) :-
	a( Attributo, AttVals),
	somma_pesata( Esempi, Attributo, AttVals, 0, Dis).

% Aggiorna la chiamata alla nuova entropia_ponderata
somma_pesata(_, _, [], Somma, Somma).
somma_pesata(Esempi, Att, [Val|Valori], SommaParziale, Somma) :-
    length(Esempi, N),
    findall(C,
            (member(e(C, Desc), Esempi), soddisfa(Desc, [Att=Val])),
            EsempiSoddisfatti),
    length(EsempiSoddisfatti, NVal),
    NVal > 0, !,
    findall(P,
            (bagof(1, member(_, EsempiSoddisfatti), L),
             length(L, NVC),
             P is NVC/NVal),
            ClDst),
    entropia_ponderata(ClDst, Gini),  % Usa la nuova funzione entropia_ponderata
    NuovaSommaParziale is SommaParziale + Gini * NVal / N,
    somma_pesata(Esempi, Att, Valori, NuovaSommaParziale, Somma)
    ;
    somma_pesata(Esempi, Att, Valori, SommaParziale, Somma).


% induce_alberi(Attributi, Valori, AttRimasti, Esempi, SAlberi):
% induce decisioni SAlberi per sottoinsiemi di Esempi secondo i Valori
% degli Attributi
induce_alberi(_,[],_,_,[]).     % nessun valore, nessun sottoalbero
induce_alberi(Att,[Val1|Valori],AttRimasti,Esempi,[Val1:Alb1|Alberi])  :-
	attval_subset(Att=Val1,Esempi,SottoinsiemeEsempi),
	induce_albero(AttRimasti,SottoinsiemeEsempi,Alb1),
	induce_alberi(Att,Valori,AttRimasti,Esempi,Alberi).

% attval_subset( Attributo = Valore, Esempi, Subset):
%   Subset è il sottoinsieme di Examples che soddisfa la condizione
%   Attributo = Valore
attval_subset(AttributoValore,Esempi,Sottoinsieme) :-
	findall(e(C,O),(member(e(C,O),Esempi),soddisfa(O,[AttributoValore])),Sottoinsieme).

% soddisfa(Oggetto, Descrizione):
soddisfa(Oggetto,Congiunzione)  :-
	\+ (member(Att=Val,Congiunzione),
	    member(Att=ValX,Oggetto),
	    ValX \== Val).

del(T,[T|C],C) :- !.
del(A,[T|C],[T|C1]) :-
	del(A,C,C1).


% Questo predicato assicura che l'albero sia disponibile
assicura_albero_entropia :-
    (   albero_gia_asserito
    ->  true
    ;   induce_albero_entropia(Albero),
        assert(alb_entropy(Albero))
    ).

% Controlla se l'albero è già asserito
% clause(alb(Albero)), questo predicato viene utilizzato per verificare
% se esiste una clausola nel database di clausole che corrisponde al
% modello alb
%(Albero). In altre parole, controlla se un albero è stato
% asserito nel database di clausole con il predicato alb/1.
albero_gia_asserito :-
    clause(alb_entropy(_), _).

% Predicato per accedere all'albero
albero_entropia(Albero) :-
    clause(alb_entropy(Albero), _).

% Rimuove l'albero dal database di clausole
rimuovi_albero :-
    retractall(alb_entropy(_)).


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



