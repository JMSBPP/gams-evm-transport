module Gams_evm



-- Given the supplies at several plants and the demands at several markets for a
-- single commodity, and we are given the unit costs of shipping the commodity from plants to markets. The economic question
-- is: how much shipment should there be between each plant and each market so as to minimize total transport cost?

-- Consider a Commodity \(X\)the supplies of \(X\)as \(S_i \, (X)\); where \(i \, \in [1:n]\) and markets \(D_j\, (X)\), where \(j \, \in [1:m]\), then:

-- \(S\, (X) = \sum_{i=1}^{n} S_i \, (X), \quad D = \sum_{i=1}^{m} D_i (X)\)


-- Consider the \(n \times m\) matrix which denotes for commodity supply on \(i < n\) the cost for fullfilling dem-- and on \(j < m\) is \(c_{ij}\). If the fullfilling demand is encoded as \(\psi_{ij} : S_{i} (X) \mapsto D_{j} \, (X)\, \subset S_{i} (X) \times \, D_{j}\);-- Then: \(c_{ij}: \psi_{ij} \to \mathbb{F}\); where \(\mathbb{F}\) is a numeric field;

-- Let \(\mathcal{Q} = \{q_{ij}\}\) the market

-- Note: \(\sum_{j=1}^{m} q_{ij} \leq S_i (X)\, ; \quad \, \sum_{i=1}^{n} \, q_{ij} \geq D_j\, (X)\)
-- \(\mathcal{C}:= \{c_{ij}\}_{i<n\, ,\,  j<m}\)

-- e.g: Consider \(n=m=1\), then \(\)




--- COMPARATIVE_STATICS


-- A SystemEquations -> Model

--- Model can be Equilibrium
-- Model can be Optimization

--- Model 1 ---> * Solvers
