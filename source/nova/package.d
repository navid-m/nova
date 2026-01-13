module nova;

public import nova.engine;

import std.math : abs;
import bindbc.glfw;
import bindbc.opengl;

unittest
{
    Nova engine;
    engine.initialize("Nova Game Engine");

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

    while (engine.running && !shouldClose(engine.window))
    {
        double currentTime = getTime();
        float deltaTime = cast(float)(currentTime - engine.lastTime);
        engine.lastTime = currentTime;

        pollEvents();

        if (getKey(engine.window, Key.Escape) == KeyEvent.Press)
            engine.running = false;

        if (getMouseButton(engine.window, Mouse.Left) == KeyEvent.Press)
        {
            double x, y;
            glfwGetCursorPos(engine.window, &x, &y);
            Vec2 worldPos = engine.screenToWorld(Vec2(cast(float) x, cast(float) y));
            auto newBall = engine.createGameObject(worldPos, Vec2(0.1f, 0.1f));
            newBall.color = Color(0, 0, 1, 1);
            engine.addRigidBody(newBall, 0.3f);
            engine.addCollider(newBall, Collider.Type.Circle, Vec2(0.05f, 0.05f));
        }

        engine.physics.update(deltaTime);

        glClearColor(0.1f, 0.1f, 0.1f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);

        foreach (obj; engine.gameObjects)
        {
            if (obj.active)
            {
                if (obj.sprite)
                    engine.renderer.drawSprite(obj.transform, *obj.sprite, obj.color);
                else if (obj.collider && obj.collider.type == Collider.Type.Circle)
                    engine.renderer.drawCircle(obj.transform, obj.color);
                else
                    engine.renderer.drawRect(obj.transform, obj.color);
            }
        }

        glfwSwapBuffers(engine.window);
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
    float aspect = 1920.0f / 1080.0f;
    Vec2 expectedWorld = Vec2(0, 0);

    Vec2 worldPos = Vec2((screenPos.x / 1920.0f - 0.5f) * 2.0f * aspect,
            -(screenPos.y / 1080.0f - 0.5f) * 2.0f);

    assert(abs(worldPos.x - expectedWorld.x) < 0.001f);
    assert(abs(worldPos.y - expectedWorld.y) < 0.001f);
}
