//
//  deck.swift
//  BeverBende
//
//  Created by J.W. Boekestijn on 2/18/19.
//  Copyright © 2019 Rug. All rights reserved.
//

import Foundation

class Game {
    public var drawPile: Deck
    public var playerDeck: Deck
    public var actrDeck1: Deck
    public var actrDeck2: Deck
    public var actrDeck3: Deck
    public var discardPile: Deck
    public var modelPlayer1: ModelPlayer
    public var modelPlayer2: ModelPlayer
    public var modelPlayer3: ModelPlayer
    public var isFinished: Bool = false
    
    public func cardsInit(ACTR: Bool) {
        if ACTR {
            drawPile.makeCardsHighlighted(fourCards: false, setTrueOrFalse: true)
            drawPile.makeCardsClickable(fourCards: false, setTrueOrFalse: false)
            if discardPile.cards.isEmpty {
                discardPile.makeCardsHighlighted(fourCards: false, setTrueOrFalse: true)
                discardPile.makeCardsClickable(fourCards: false, setTrueOrFalse: false)

            }
        } else {
            drawPile.makeCardsHighlighted(fourCards: false, setTrueOrFalse: true)
            drawPile.makeCardsClickable(fourCards: false, setTrueOrFalse: true)
            if discardPile.cards.isEmpty {
                discardPile.makeCardsHighlighted(fourCards: false, setTrueOrFalse: true)
                discardPile.makeCardsClickable(fourCards: false, setTrueOrFalse: true)
            }
        }
    }
    // took-drawpile action = 1
    // nieuw geschatte waarde afgespeelde waarde op discardpile / 2
    
    // took-discard action = 2
    // dan weet je zeker welke waarde er ligt, want dat is waarde van discardPile kaart
    
    
    private func ACTRUpdateKnowledge(model: ModelPlayer, deck: Deck, action: Int, position: Int, value: Int) {
        let playerNumber = model.playerNumber
        if playerNumber == 1 {
            modelPlayer2.addActions(actionNum: action, player: 1, position: position, estimatedValue: value)
            modelPlayer3.addActions(actionNum: action, player: 1, position: position, estimatedValue: value)
        } else if playerNumber == 2 {
            modelPlayer1.addActions(actionNum: action, player: 2, position: position, estimatedValue: value)
            modelPlayer3.addActions(actionNum: action, player: 2, position: position, estimatedValue: value)
        } else if playerNumber == 3 {
            modelPlayer1.addActions(actionNum: action, player: 3, position: position, estimatedValue: value)
            modelPlayer2.addActions(actionNum: action, player: 3, position: position, estimatedValue: value)
        }
    }
    
    
    public func initACTRModelActions(model: ModelPlayer, deck: Deck) {
        model.run()
        model.modifyLastAction(slot: "isa", value: "start-info")
        model.modifyLastAction(slot: "left", value: String(deck.returnCardAtPos(position: 0)))
        model.modifyLastAction(slot: "right", value: String(deck.returnCardAtPos(position: 3)))
    }
    
    
    public func ACTRModelActions(model: ModelPlayer, deck: Deck) -> (Int, Int) {
        //Start turn
        model.run()
        model.run()
        //Get max and minimum value of the four cards of the model and return the highest and lowest to ACT-R
        let max_tuple = max(model: model)
        let max_val = max_tuple.0
        let max_pos = max_tuple.1
        model.modifyLastAction(slot: "isa", value: "compare-cards")
        model.modifyLastAction(slot: "max", value: String(max_val))
        model.modifyLastAction(slot: "max-pos", value: String(max_pos))
        let min_tuple = min(model: model)
        let min_val = min_tuple.0
        let min_pos = min_tuple.1
        model.modifyLastAction(slot: "min", value: String(min_val))
        model.modifyLastAction(slot: "min-pos", value: String(min_pos))
        
        model.run()
        
        model.modifyLastAction(slot: "isa", value: "moves")
        model.buffers["actions"]?.slotvals["discard"] = nil
        model.modifyLastAction(slot: "draw", value: String(drawPile.returnCardAtPos(position: drawPile.cards.endIndex-1)))
//        model.modifyLastAction(slot: "draw", value: "sneak-peek")

        model.run()
        
        //If the action required is a sneakpeek
        if model.buffers["action"]?.slotvals["action"]?.text() == "peek" {
            //Either ACT-R doesn't know where to look, then a random card will be looked at. Otherwise the speciefied card will be used.
            if model.buffers["action"]?.slotvals["position"]?.text() == "random"{
                //let Swift pick a random card to look at
                let position = Int(arc4random_uniform(3))
                let value = deck.returnCardAtPos(position: position)
                model.modifyLastAction(slot: "isa", value: "peek")
                model.modifyLastAction(slot: "position", value: String(position))
                model.modifyLastAction(slot: "value", value: String(value))
                
            } else {
                //Look at the card chosen by ACT-R. 
                let position = Int((model.buffers["action"]?.slotvals["position"]?.number())!)
                let value = deck.returnCardAtPos(position: position)
                model.modifyLastAction(slot: "isa", value: "peek")
                model.modifyLastAction(slot: "position", value: String(position))
                model.modifyLastAction(slot: "value", value: String(value))
                }
        }
        
        model.run()
        print(model.buffers)
        
        //print(model.dm.chunks)
        //print(model.dm.chunks["player3"]?.activation())
        // TODO: ACT-R Model actions are performed here
        print(model.buffers["action"]?.slotvals["action"]?.text())
        if model.buffers["action"]?.slotvals["action"]?.text() == "discard-draw" {
            return (0, 0)
        } else if model.buffers["action"]?.slotvals["action"]?.text() == "took-draw" {
            let position = Int((model.buffers["action"]?.slotvals["position"]?.number())!)
            // should be the value of the card that will be swapped and put in the discardpile later on
            var value = deck.cards[position].value / 2
            // needed so that special cards still have avg of 5
            if value == 50 {
                value = 5
            }
            ACTRUpdateKnowledge(model: model, deck: deck, action: 1, position: position, value: value)
            return (1, position)
        } else if model.buffers["action"]?.slotvals["action"]?.text() == "took-discard" {
            let position = Int((model.buffers["action"]?.slotvals["position"]?.number())!)
            var value = discardPile.cards[discardPile.cards.endIndex].value / 2
            // needed so that special cards still have avg of 5
            if value == 50 {
                value = 5
            }
            ACTRUpdateKnowledge(model: model, deck: deck, action: 2, position: position, value: value)
            return (2, position)
        } else {
            return (-1, -1)
        }
    }
    
    public func cardActions(pos: Int, pileClicked: Int, deck: Deck) {
        // if the drawPile is clicked
        if pileClicked == 1 {
            discardPile.appendCard(fromDeck: deck, pos: pos)
            deck.popAndInsertCard(fromDeck: drawPile, pos: pos)
        } else if pileClicked == 2 {
            // if the discardPile is clicked
            deck.swapCardsAtPos(fromDeck: discardPile, pos: pos)
        }
    }
    
        
    private func max(model: ModelPlayer) -> (Double, Int) {
        var highest: Double = -1
        var highestpos: Int = 5
        let position = ["pos0","pos1","pos2","pos3"]
        var j = 0
        for i in position {
            let value = model.buffers["action"]?.slotvals[i]?.number()
            if value != nil {
                if value! > highest {
                    highest = value!
                    highestpos = j
                }
            }
            j += 1
        }
        return (highest,highestpos)
    }
        
    private func min(model: ModelPlayer) -> (Double, Int)  {
        var lowest: Double = 100
        var lowestpos: Int = 5
        let position = ["pos0","pos1","pos2","pos3"]
        var j = 0
        for i in position {
            let value = model.buffers["action"]?.slotvals[i]?.number()
            if value != nil {
                if value! < lowest {
                    lowest = value!
                    lowestpos = j
                }
            }
            j += 1
        }
        return(lowest,lowestpos)
    }
    
    public func beverBende(){
        playerDeck.makeCardsFaceUp(fourCards: true, setTrueOrFalse: true)
        actrDeck1.makeCardsFaceUp(fourCards: true, setTrueOrFalse: true)
        actrDeck2.makeCardsFaceUp(fourCards: true, setTrueOrFalse: true)
        actrDeck3.makeCardsFaceUp(fourCards: true, setTrueOrFalse: true)
    }

    public func initGame() {
        playerDeck.showOuterCards()
    }
    
    public func hideCard() {
        playerDeck.hideOuterCards()
    }
    
    init() {
        self.drawPile = Deck(completeDeck: true)
        self.playerDeck = Deck(drawPile: drawPile)
        self.actrDeck1 = Deck(drawPile: drawPile)
        self.actrDeck2 = Deck(drawPile: drawPile)
        self.actrDeck3 = Deck(drawPile: drawPile)
        self.discardPile = Deck()
        self.modelPlayer1 = ModelPlayer(playerNumber: 1)
        self.modelPlayer2 = ModelPlayer(playerNumber: 2)
        self.modelPlayer3 = ModelPlayer(playerNumber: 3)
    }
}
