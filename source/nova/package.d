module nova;

public import nova.engine;

import std.math : abs;

unittest
{
    struct PlayerControl
    {
        float speed = 2.0f;
    }

    class PlayerSystem : ISystem
    {
        Input* input;
        Scene scene;

        this(Scene s, Input* i)
        {
            scene = s;
            input = i;
        }

        void update(float dt)
        {
            foreach (obj; scene.gameObjects)
            {
                auto control = obj.getComponent!PlayerControl;
                if (control)
                {
                    if (input.isKeyDown(Key.W))
                        obj.transform.position.y += control.speed * dt;
                    if (input.isKeyDown(Key.S))
                        obj.transform.position.y -= control.speed * dt;
                    if (input.isKeyDown(Key.A))
                        obj.transform.position.x -= control.speed * dt;
                    if (input.isKeyDown(Key.D))
                        obj.transform.position.x += control.speed * dt;
                }
            }
        }
    }

    Nova engine;
    engine.initialize("Nova Game Engine", 1920, 1080, 90);

    auto explosionEmitter = engine.createParticleEmitter(Vec2(0, 0), 200);

    explosionEmitter.active = true;
    explosionEmitter.emissionRate = 0;
    explosionEmitter.loop = false;
    explosionEmitter.velocityMin = Vec2(-1.0f, 0.5f);
    explosionEmitter.velocityMax = Vec2(1.0f, 1.5f);
    explosionEmitter.colorStart = Color(1.0f, 0.5f, 0.2f, 1.0f);
    explosionEmitter.colorEnd = Color(1.0f, 0.0f, 0.0f, 0.0f);
    explosionEmitter.lifetimeMin = 0.3f;
    explosionEmitter.lifetimeMax = 0.8f;
    explosionEmitter.sizeStart = 0.08f;
    explosionEmitter.sizeEnd = 0.0f;
    explosionEmitter.gravity = Vec2(0, -1.0f);
    explosionEmitter.rotationSpeedMin = -5.0f;
    explosionEmitter.rotationSpeedMax = 5.0f;

    engine.physics.onGroundHit = (GameObject* obj) {
        if (obj.rigidbody && !obj.rigidbody.isStatic)
        {
            explosionEmitter.position = Vec2(obj.transform.position.x, -0.4f);
            explosionEmitter.burst(20);
        }
    };

    auto texture = engine.loadTexture("test_sprite.ppm");
    auto ground = engine.createGameObject(Vec2(0, -0.5f), Vec2(1.8f, 0.2f));

    ground.color = Color(0.5f, 0.5f, 0.5f, 1);
    engine.addRigidBody(ground, 1, true);
    engine.addCollider(ground, Collider.Type.Rectangle, Vec2(1.8f, 0.2f));

    auto ball1 = engine.createGameObject(Vec2(-0.3f, 0.8f), Vec2(0.2f, 0.2f));

    ball1.color = Color(1, 0, 0, 1);
    engine.addRigidBody(ball1, 1);
    engine.addCollider(ball1, Collider.Type.Circle, Vec2(0.1f, 0.1f));

    auto ball2 = engine.createGameObject(Vec2(0.3f, 0.6f), Vec2(0.15f, 0.15f));

    ball2.color = Color(0, 1, 0, 1);
    engine.addRigidBody(ball2, 0.5f);
    engine.addCollider(ball2, Collider.Type.Circle, Vec2(0.075f, 0.075f));

    if (texture)
    {
        auto spriteObj = engine.createGameObject(Vec2(-0.6f, 0.2f), Vec2(0.3f, 0.3f));
        engine.addSprite(spriteObj, texture);
        auto frameObj = engine.createGameObject(Vec2(0.6f, 0.2f), Vec2(0.2f, 0.2f));
        auto frame = engine.createFrame(0, 0, 2, 2, 4, 4);
        engine.addSprite(frameObj, texture, frame);
    }

    auto font = engine.loadFont("DejaVuSans.ttf", 48);
    if (font)
    {
        auto textObj = engine.createGameObject(Vec2(-0.9f, 0.8f), Vec2(0.002f, 0.002f));
        textObj.text = new Text("Hello Nova Engine!", font);
        textObj.text.typewriter = true;
        textObj.text.color = Color(1, 1, 1, 1);
    }

    while (engine.running && !shouldClose(engine.window))
    {
        double currentTime = getTime();
        float deltaTime = cast(float)(currentTime - engine.lastTime);
        engine.lastTime = currentTime;

        engine.input.update();
        pollEvents();

        if (getKey(engine.window, Key.Escape) == KeyEvent.Press)
            engine.running = false;

        if (engine.input.isKeyPressed(Key.Q))
        {
            import std.stdio;

            auto scene2 = new Scene();
            engine.loadScene(scene2);

            auto player = engine.createGameObject(Vec2(0, 0), Vec2(0.2f, 0.2f));
            player.color = Color(0, 1, 0, 1);
            player.addComponent(new PlayerControl(1.5f));
            scene2.systems ~= new PlayerSystem(scene2, &engine.input);
        }

        if (getMouseButton(engine.window, Mouse.Left) == KeyEvent.Press)
        {
            double x, y;
            getCursorPosition(engine.window, &x, &y);
            Vec2 worldPos = engine.screenToWorld(Vec2(cast(float) x, cast(float) y));
            auto newBall = engine.createGameObject(worldPos, Vec2(0.1f, 0.1f));
            newBall.color = Color(0, 0, 1, 1);
            engine.addRigidBody(newBall, 0.3f);
            engine.addCollider(newBall, Collider.Type.Circle, Vec2(0.05f, 0.05f));
        }

        if (engine.activeScene)
            engine.activeScene.update(deltaTime);

        clearColor(0.1f, 0.1f, 0.1f, 1.0f);
        clear(BufferBit.Color);

        foreach (obj; engine.gameObjects)
        {
            if (obj.active)
            {
                if (obj.sprite)
                    engine.renderer.drawSprite(obj.transform, *obj.sprite, obj.color, engine.activeScene.camera);
                else if (obj.text)
                    engine.renderer.drawText(obj.transform, *obj.text, engine.activeScene.camera);
                else if (obj.collider && obj.collider.type == Collider.Type.Circle)
                    engine.renderer.drawCircle(obj.transform, obj.color, engine.activeScene.camera);
                else
                    engine.renderer.drawRect(obj.transform, obj.color, engine.activeScene.camera);
            }
        }

        foreach (emitter; engine.particleEmitters)
        {
            engine.renderer.drawParticles(*emitter, engine.activeScene.camera);
        }

        swapBuffers(engine.window);
    }

    engine.cleanup();
}

unittest
{
    Input input;

    assert(!input.isKeyDown(Key.W));
    assert(!input.isKeyPressed(Key.W));
    assert(!input.isMouseDown(Mouse.Left));

    input.keys[Key.W] = true;
    input.keysPressed[Key.W] = true;
    assert(input.isKeyDown(Key.W));
    assert(input.isKeyPressed(Key.W));

    input.update();
    assert(input.isKeyDown(Key.W));
    assert(!input.isKeyPressed(Key.W));

    input.mouseButtons[Mouse.Left] = true;
    input.mousePressed[Mouse.Left] = true;
    input.mousePos = Vec2(100, 200);

    assert(input.isMouseDown(Mouse.Left));
    assert(input.isMousePressed(Mouse.Left));
    assert(input.mousePos.x == 100);
    assert(input.mousePos.y == 200);

    Vec2 screenPos = Vec2(960, 540);
    Vec2 expectedWorld = Vec2(0, 0);
    Vec2 worldPos = Vec2((screenPos.x / 1920.0f - 0.5f) * 2.0f,
            -(screenPos.y / 1080.0f - 0.5f) * 2.0f);

    assert(abs(worldPos.x - expectedWorld.x) < 0.001f);
    assert(abs(worldPos.y - expectedWorld.y) < 0.001f);
}
