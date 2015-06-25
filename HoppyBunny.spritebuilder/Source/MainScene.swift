import Foundation

class MainScene: CCNode, CCPhysicsCollisionDelegate {
    weak var hero: CCSprite!    // Unwrap the CCSprite to weak variable hero.
    weak var gamePhysicsNode: CCPhysicsNode! //Unwrap CCPhysicsNode to variable gamePhysicsNode
    weak var ground1 : CCSprite!
    weak var ground2 : CCSprite!
    weak var obstaclesLayer : CCNode!
    weak var restartButton : CCButton!
    weak var scoreLabel : CCLabelTTF!
    var points : NSInteger = 0
    var grounds = [CCSprite]()  // initializes an empty array
    var sinceTouch : CCTime = 0     // Set a new variable sinceTouch as variable type CCTime in order to keep track of the time since last touched.
    var scrollSpeed : CGFloat = 80      // Set a new variable scrollSpeed of type CGFloat to initiate the scrolling from side to side
    var obstacles : [CCNode] = []
    var gameOver = false
    let firstObstaclePosition : CGFloat = 280
    let distanceBetweenObstacles : CGFloat = 160
    

    func restart() {
        let scene = CCBReader.loadAsScene("MainScene")
        CCDirector.sharedDirector().presentScene(scene)
    }
    
    func triggerGameOver() {
        if (gameOver == false) {
            gameOver = true
            restartButton.visible = true
            scrollSpeed = 0
            hero.rotation = 90
            hero.physicsBody.allowsRotation = false
            
            // just in case
            hero.stopAllActions()
            
            let move = CCActionEaseBounceOut(action: CCActionMoveBy(duration: 0.2, position: ccp(0, 4)))
            let moveBack = CCActionEaseBounceOut(action: move.reverse())
            let shakeSequence = CCActionSequence(array: [move, moveBack])
            runAction(shakeSequence)
        }
    }
    
    func ccPhysicsCollisionBegin(pair: CCPhysicsCollisionPair!, hero: CCNode!, level: CCNode!) -> Bool {
        triggerGameOver()
        return true
    }
    
    func ccPhysicsCollisionBegin(pair: CCPhysicsCollisionPair!, hero nodeA: CCNode!, goal: CCNode!) -> Bool {
        goal.removeFromParent()
        points++
        scoreLabel.string = String(points)
        return true
    }
    
    func didLoadFromCCB () {
        userInteractionEnabled = true   //Allow user Interactions to be enabled in this scope
        grounds.append(ground1)
        grounds.append(ground2)
        spawnNewObstacle()
        spawnNewObstacle()
        spawnNewObstacle()
        gamePhysicsNode.collisionDelegate = self
    }
    
    func spawnNewObstacle() {
        var prevObstaclePos = firstObstaclePosition
        if obstacles.count > 0 {
            prevObstaclePos = obstacles.last!.position.x
        }

        // create and add a new obstacle
        let obstacle = CCBReader.load("Obstacle") as! Obstacle   // replaced this line
        obstacle.position = ccp(prevObstaclePos + distanceBetweenObstacles, 0)
        obstacle.setupRandomPosition()   // add this line
        obstaclesLayer.addChild(obstacle)   // replaced this line
        obstacles.append(obstacle)
    }
    
    override func touchBegan(touch: CCTouch!, withEvent event: CCTouchEvent!) {
        if (gameOver == false) {
            hero.physicsBody.applyImpulse(ccp(0, 400))
            hero.physicsBody.applyAngularImpulse(10000)
            sinceTouch = 0
        }
    }
    

    override func update(delta: CCTime) {
        let velocityY = clampf(Float(hero.physicsBody.velocity.y), -Float(CGFloat.max), 200) // We are setting a new variable equal to a clamping (or limiting) of our Y velocity to a maximum of 200
        
        hero.physicsBody.velocity = ccp(0, CGFloat(velocityY))  // We are using the variable we just created to pass as a reference to now effectively limit our velocity
        
        sinceTouch += delta // We are adding the time delta to the time since touch on every update in order to keep track of when the last touch has actually occured
        
        hero.rotation = clampf(hero.rotation, -30, 90)  // Here we clamp (limit) our hero's rotation so that he does not aimlessly spin around the same axis forever
        
        if (hero.physicsBody.allowsRotation) {
            let angularVelocity = clampf(Float(hero.physicsBody.angularVelocity), -2, 1) //If we are now in a state where rotation is allowed then we set this variable to the limit of our angular velocity as well
            
            hero.physicsBody.angularVelocity = CGFloat(angularVelocity) // Finally our angular velocity decay rate is placed into effect now that we have this limitation
        }
        
        if (sinceTouch > 0.3) {
            let impulse = -18000.0 * delta // If the time since the last touch is greater than 3 tenths of a second than we create a constant variable for this scope as the time delta * -18000.0
            
            hero.physicsBody.applyAngularImpulse(CGFloat(impulse))  // If the time since the last touch is greater than 3 tenths of a second than we also apply our angular decay rate
            
        }
        
        hero.position = ccp(hero.position.x + scrollSpeed * CGFloat(delta), hero.position.y) // Here we start the movement of our hero by changing his X coordinate positioning by adding on every update to his position the scrollSpeed we have designated (here to 80 in this scope) multiplied by CGFloat(delta) which signifies the time in this scope.
        
       gamePhysicsNode.position = ccp(gamePhysicsNode.position.x - scrollSpeed * CGFloat(delta), gamePhysicsNode.position.y) // We set our variable equal to it's x-position minus the scroll speed * update time delta
        
        let scale = CCDirector.sharedDirector().contentScaleFactor
        gamePhysicsNode.position = ccp(round(gamePhysicsNode.position.x * scale) / scale, round(gamePhysicsNode.position.y * scale) / scale)
        hero.position = ccp(round(hero.position.x * scale) / scale, round(hero.position.y * scale) / scale)
        
        // loop the ground whenever a ground image was moved entirely outside the screen
        for ground in grounds {
            let groundWorldPosition = gamePhysicsNode.convertToWorldSpace(ground.position)
            let groundScreenPosition = convertToNodeSpace(groundWorldPosition)
            if groundScreenPosition.x <= (-ground.contentSize.width) {
                ground.position = ccp(ground.position.x + ground.contentSize.width * 2, ground.position.y)
            }
        }
        
        for obstacle in obstacles.reverse() {
            let obstacleWorldPosition = gamePhysicsNode.convertToWorldSpace(obstacle.position)
            let obstacleScreenPosition = convertToNodeSpace(obstacleWorldPosition)
            
            // obstacle moved past left side of screen?
            if obstacleScreenPosition.x < (-obstacle.contentSize.width) {
                obstacle.removeFromParent()
                obstacles.removeAtIndex(find(obstacles, obstacle)!)
                
                // for each removed obstacle, add a new one
                spawnNewObstacle()
            }
        }
        
    }
    

    
}

