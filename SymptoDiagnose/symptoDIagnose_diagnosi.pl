:- use_module(symptoDiagnose_tree_induction_entropy).
:- use_module(symptoDiagnose_tree_induction_gini).


% ================================================================================
% classifica( +Oggetto, -Classe, t(+Att,+Valori))
%  Oggetto: [Attributo1=Valore1, .. , AttributoN=ValoreN]
%  Classe: classe a cui potrebbe appartenere un oggetto caratterizzato da quelle coppie
%  Attributo=Valore
%  t(-Att,-Valori): Albero di Decisione
% presuppone sia stata effettuata l'induzione dell'Albero di Decisione

classifica(Oggetto,nc,t(Att,Valori)) :- % dato t(+Att,+Valori), Oggetto è della Classe
	member(Att=Val,Oggetto),  % se Att=Val è elemento della lista Oggetto
        member(Val:null,Valori). % e Val:null è in Valori

classifica(Oggetto,Classe,t(Att,Valori)) :- % dato t(+Att,+Valori), Oggetto è della Classe
	member(Att=Val,Oggetto),  % se Att=Val è elemento della lista Oggetto
        member(Val:l(Classe),Valori). % e Val:l(Classe) è in Valori

classifica(Oggetto,Classe,t(Att,Valori)) :-
	member(Att=Val,Oggetto),  % se Att=Val è elemento della lista Oggetto
	delete(Oggetto,Att=Val,Resto),
	member(Val:t(AttFiglio,ValoriFiglio),Valori),
	classifica(Resto,Classe,t(AttFiglio,ValoriFiglio)).

diagnosi_albero_entropia(Malattia,Lista):-
    assicura_albero_entropia,
    albero_entropia(Albero),
    classifica(Lista,Malattia,Albero).

diagnosi_albero_gini(Malattia,Lista):-
    assicura_albero_gini,
    albero_gini(Albero),
    classifica(Lista,Malattia,Albero).


