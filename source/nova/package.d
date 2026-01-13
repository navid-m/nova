module nova;

public import nova.engine;

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

    engine.run();
    engine.cleanup();
}
