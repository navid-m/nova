import bindbc.glfw;
import bindbc.opengl;
import std.stdio;
import std.math;
import std.algorithm;

/** 
 * Some two dimensional vector. 
 */
struct Vec2
{
    float x, y;
}

/** 
 * Some RGBA colour.
 */
struct Color
{
    float r, g, b, a;
}

/** 
 * A transformation between two 2D vectors.
 */
struct Transform
{
    Vec2 position;
    float rotation = 0;
    Vec2 scale = Vec2(1, 1);
}

/** 
 * Some rigid body in the physics world.
 */
struct RigidBody
{
    Vec2 velocity = Vec2(0, 0);
    float mass = 1;
    bool isStatic = false;
    float restitution = 0.8f;
}

/** 
 * Some collider in the physics world.
 */
struct Collider
{
    enum Type
    {
        Circle,
        Rectangle
    }

    Type type;
    Vec2 size;
}

/** 
 * An object in the physics world.
 */
struct GameObject
{
    Transform transform;
    RigidBody* rigidbody;
    Collider* collider;
    Color color = Color(1, 1, 1, 1);
    bool active = true;
}

/** 
 * The main renderer of the game.
 *
 * This is the heart of any game built with Nova.
 */
struct Renderer
{
    uint shaderProgram, rectVAO, rectVBO, circleVAO, circleVBO;

    /** 
     * Initialize the renderer, this must be called prior to the usage of the renderer
     * at all. 
     */
    void initialize()
    {
        const char* vertexShader = `
            #version 330 core
            layout (location = 0) in vec2 aPos;
            uniform mat4 transform;
            void main() {
                gl_Position = transform * vec4(aPos, 0.0, 1.0);
            }`;

        const char* fragmentShader = `
            #version 330 core
            out vec4 FragColor;
            uniform vec4 color;
            void main() {
                FragColor = color;
            }`;

        uint vs = glCreateShader(GL_VERTEX_SHADER);
        glShaderSource(vs, 1, &vertexShader, null);
        glCompileShader(vs);

        uint fs = glCreateShader(GL_FRAGMENT_SHADER);
        glShaderSource(fs, 1, &fragmentShader, null);
        glCompileShader(fs);

        shaderProgram = glCreateProgram();
        glAttachShader(shaderProgram, vs);
        glAttachShader(shaderProgram, fs);
        glLinkProgram(shaderProgram);

        glDeleteShader(vs);
        glDeleteShader(fs);

        float[] vertices = [
            -0.5f, -0.5f, 0.5f, -0.5f, 0.5f, 0.5f, -0.5f, 0.5f
        ];

        glGenVertexArrays(1, &rectVAO);
        glGenBuffers(1, &rectVBO);
        glBindVertexArray(rectVAO);
        glBindBuffer(GL_ARRAY_BUFFER, rectVBO);
        glBufferData(GL_ARRAY_BUFFER, vertices.length * float.sizeof, vertices.ptr, GL_STATIC_DRAW);
        glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 2 * float.sizeof, cast(void*) 0);
        glEnableVertexAttribArray(0);

        float[] circleVertices;
        int segments = 32;
        for (int i = 0; i <= segments; i++)
        {
            float angle = 2.0f * 3.14159f * i / segments;
            circleVertices ~= cos(angle) * 0.5f;
            circleVertices ~= sin(angle) * 0.5f;
        }

        glGenVertexArrays(1, &circleVAO);
        glGenBuffers(1, &circleVBO);
        glBindVertexArray(circleVAO);
        glBindBuffer(GL_ARRAY_BUFFER, circleVBO);
        glBufferData(GL_ARRAY_BUFFER, circleVertices.length * float.sizeof,
                circleVertices.ptr, GL_STATIC_DRAW);
        glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 2 * float.sizeof, cast(void*) 0);
        glEnableVertexAttribArray(0);
    }

    /** 
     * Draw some circle via the renderer.
     *
     * Params:
     *   t = The transform 
     *   c = The colour of the circle in ARGB format
     */
    void drawCircle(Transform t, Color c)
    {
        glUseProgram(shaderProgram);

        float aspect = 1920.0f / 1080.0f;
        float[16] matrix = [
            t.scale.x / aspect, 0, 0, 0, 0, t.scale.y, 0, 0, 0, 0, 1, 0,
            t.position.x, t.position.y, 0, 1
        ];

        glUniformMatrix4fv(glGetUniformLocation(shaderProgram, "transform"), 1,
                GL_FALSE, matrix.ptr);
        glUniform4f(glGetUniformLocation(shaderProgram, "color"), c.r, c.g, c.b, c.a);
        glBindVertexArray(circleVAO);
        glDrawArrays(GL_TRIANGLE_FAN, 0, 33);
    }

    /** 
     * Draw some rectangle via the renderer.
     *
     * Params:
     *   t = The transform
     *   c = The colour of the rectangle in ARGB format
     */
    void drawRect(Transform t, Color c)
    {
        glUseProgram(shaderProgram);

        float[16] matrix = [
            t.scale.x, 0, 0, 0, 0, t.scale.y, 0, 0, 0, 0, 1, 0, t.position.x,
            t.position.y, 0, 1
        ];

        glUniformMatrix4fv(glGetUniformLocation(shaderProgram, "transform"), 1,
                GL_FALSE, matrix.ptr);
        glUniform4f(glGetUniformLocation(shaderProgram, "color"), c.r, c.g, c.b, c.a);
        glBindVertexArray(rectVAO);
        glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    }
}

/** 
 * The physics engine.
 */
struct Physics
{
    GameObject*[] objects;
    Vec2 gravity = Vec2(0, -0.5f);

    /** 
     * Add some object to the physics world.
     * 
     * Params:
     *   obj = The object to add 
     */
    void addObject(GameObject* obj)
    {
        objects ~= obj;
    }

    /** 
     * Update the physics loop.
     *
     * Params:
     *   dt = Delta time 
     */
    void update(float dt)
    {
        foreach (obj; objects)
        {
            if (!obj.rigidbody || obj.rigidbody.isStatic)
                continue;

            obj.rigidbody.velocity.y += gravity.y * dt;
            obj.transform.position.y += obj.rigidbody.velocity.y * dt;

            if (obj.transform.position.y < -0.4f)
            {
                obj.transform.position.y = -0.4f;
                obj.rigidbody.velocity.y = -obj.rigidbody.velocity.y * 0.8f;
            }
        }
    }

    /** 
     * Check for collisions in the physics world. 
     */
    void checkCollisions()
    {
        for (size_t i = 0; i < objects.length; i++)
        {
            for (size_t j = i + 1; j < objects.length; j++)
            {
                if (isColliding(objects[i], objects[j]))
                {
                    resolveCollision(objects[i], objects[j]);
                }
            }
        }
    }

    /** 
     * Determine whether two game objects are colliding.
     *
     * Params:
     *   a = Object A
     *   b = Object B
     *
     * Returns: Whether or not they are colliding 
     */
    bool isColliding(GameObject* a, GameObject* b)
    {
        if (!a.collider || !b.collider)
            return false;

        float dx = a.transform.position.x - b.transform.position.x;
        float dy = a.transform.position.y - b.transform.position.y;
        float distance = sqrt(dx * dx + dy * dy);

        if (a.collider.type == Collider.Type.Circle && b.collider.type == Collider.Type.Circle)
        {
            return distance < (a.collider.size.x + b.collider.size.x);
        }

        return false;
    }

    /** 
     * Resolve a collision between two game objects.
     *
     * Params:
     *   a = Object A 
     *   b = Object B
     */
    void resolveCollision(GameObject* a, GameObject* b)
    {
        if (!a.rigidbody || !b.rigidbody)
            return;

        Vec2 normal;
        float dx = b.transform.position.x - a.transform.position.x;
        float dy = b.transform.position.y - a.transform.position.y;
        float distance = sqrt(dx * dx + dy * dy);

        if (distance > 0)
        {
            normal.x = dx / distance;
            normal.y = dy / distance;
        }

        float relativeVelocityX = b.rigidbody.velocity.x - a.rigidbody.velocity.x;
        float relativeVelocityY = b.rigidbody.velocity.y - a.rigidbody.velocity.y;
        float velocityAlongNormal = relativeVelocityX * normal.x + relativeVelocityY * normal.y;

        if (velocityAlongNormal > 0)
            return;

        float e = min(a.rigidbody.restitution, b.rigidbody.restitution);
        float j = -(1 + e) * velocityAlongNormal / (1 / a.rigidbody.mass + 1 / b.rigidbody.mass);

        Vec2 impulse = Vec2(j * normal.x, j * normal.y);

        if (!a.rigidbody.isStatic)
        {
            a.rigidbody.velocity.x -= impulse.x / a.rigidbody.mass;
            a.rigidbody.velocity.y -= impulse.y / a.rigidbody.mass;
        }

        if (!b.rigidbody.isStatic)
        {
            b.rigidbody.velocity.x += impulse.x / b.rigidbody.mass;
            b.rigidbody.velocity.y += impulse.y / b.rigidbody.mass;
        }
    }
}

/** 
 * The engine instance.
 */
struct Nova
{
    GLFWwindow* window;
    bool running;
    Renderer renderer;
    Physics physics;
    GameObject*[] gameObjects;
    double lastTime;

    /** 
     * Initialize the game engine.
     *
     * Params:
     *   title = The window title 
     */
    void initialize(string title)
    {
        if (loadGLFW() != glfwSupport)
        {
            writeln("Could not load GLFW");
            return;
        }

        glfwInit();
        glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
        glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);

        window = glfwCreateWindow(1920, 1080, title.ptr, null, null);
        if (!window)
        {
            glfwTerminate();
            return;
        }

        glfwMakeContextCurrent(window);

        GLSupport glSupport = loadOpenGL();
        if (glSupport == GLSupport.noLibrary)
        {
            writeln("ERROR: Could not load OpenGL");
            return;
        }

        glViewport(0, 0, 1920, 1080);
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

        renderer.initialize();
        lastTime = glfwGetTime();
        running = true;
    }

    /** 
     * Create some game object.
     *
     * Params:
     *   pos = Origin of the new game object as a 2D vector 
     *   scale = Scale of the game object, defaults to 1.
     *
     * Returns: A reference to the new game object that has been created. 
     */
    GameObject* createGameObject(Vec2 pos, Vec2 scale = Vec2(1, 1))
    {
        GameObject* obj = new GameObject();
        obj.transform.position = pos;
        obj.transform.scale = scale;
        gameObjects ~= obj;
        return obj;
    }

    /** 
     * Add a game object to the world as a rigid body.
     *
     * Params:
     *   obj = The object
     *   mass = The mass of the object
     *   isStatic = Whether or not it is static, defaults to false
     */
    void addRigidBody(GameObject* obj, float mass = 1, bool isStatic = false)
    {
        obj.rigidbody = new RigidBody();
        obj.rigidbody.mass = mass;
        obj.rigidbody.isStatic = isStatic;
        physics.addObject(obj);
    }

    /** 
     * Add a collider to the world.
     *
     * Params:
     *   obj = Source object 
     *   type = Type of collider
     *   size = Size of object as a 2D vector
     */
    void addCollider(GameObject* obj, Collider.Type type, Vec2 size)
    {
        obj.collider = new Collider();
        obj.collider.type = type;
        obj.collider.size = size;
    }

    /** 
     * Run the game.
     */
    void run()
    {
        while (running && !glfwWindowShouldClose(window))
        {
            double currentTime = glfwGetTime();
            float deltaTime = cast(float)(currentTime - lastTime);
            lastTime = currentTime;

            glfwPollEvents();

            physics.update(deltaTime);

            glClearColor(0.1f, 0.1f, 0.1f, 1.0f);
            glClear(GL_COLOR_BUFFER_BIT);

            foreach (obj; gameObjects)
            {
                if (obj.active)
                {
                    if (obj.collider && obj.collider.type == Collider.Type.Circle)
                        renderer.drawCircle(obj.transform, obj.color);
                    else
                        renderer.drawRect(obj.transform, obj.color);
                }
            }

            glfwSwapBuffers(window);
        }
    }

    /** 
     * Destroy the window and clean up the underlying GLFW resources.
     */
    void cleanup()
    {
        glfwDestroyWindow(window);
        glfwTerminate();
    }
}

void main()
{
    Nova engine;
    engine.initialize("Nova Game Engine");

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

    engine.run();
    engine.cleanup();
}
