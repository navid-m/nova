module nova.engine;

import bindbc.glfw;
import bindbc.opengl;
import std.stdio;
import std.math;
import std.algorithm;
import std.string;
import std.random;

/** 
 * Some two dimensional vector. 
 */
struct Vec2
{
    float x, y;
}

/** 
 * Input state for keyboard and mouse.
 */
struct Input
{
    bool[512] keys;
    bool[512] keysPressed;
    bool[512] keysReleased;
    bool[8] mouseButtons;
    bool[8] mousePressed;
    bool[8] mouseReleased;
    Vec2 mousePos;
    Vec2 mouseDelta;
    Vec2 scrollDelta;

    void update()
    {
        foreach (i; 0 .. 512)
        {
            keysPressed[i] = false;
            keysReleased[i] = false;
        }
        foreach (i; 0 .. 8)
        {
            mousePressed[i] = false;
            mouseReleased[i] = false;
        }
        scrollDelta = Vec2(0, 0);
        mouseDelta = Vec2(0, 0);
    }

    bool isKeyDown(int key)
    {
        return keys[key];
    }

    bool isKeyPressed(int key)
    {
        return keysPressed[key];
    }

    bool isKeyReleased(int key)
    {
        return keysReleased[key];
    }

    bool isMouseDown(int button)
    {
        return mouseButtons[button];
    }

    bool isMousePressed(int button)
    {
        return mousePressed[button];
    }

    bool isMouseReleased(int button)
    {
        return mouseReleased[button];
    }
}

/** 
 * Common key events.
 */
enum KeyEvent
{
    Release = 0,
    Press = 1,
    Repeat = 2,
    Unknown = -1
}

/** 
 * Common key constants.
 */
enum Key
{
    Space = 32,
    Apostrophe = 39,
    Comma = 44,
    Minus = 45,
    Period = 46,
    Slash = 47,
    Num0 = 48,
    Num1 = 49,
    Num2 = 50,
    Num3 = 51,
    Num4 = 52,
    Num5 = 53,
    Num6 = 54,
    Num7 = 55,
    Num8 = 56,
    Num9 = 57,
    Semicolon = 59,
    Equal = 61,
    A = 65,
    B = 66,
    C = 67,
    D = 68,
    E = 69,
    F = 70,
    G = 71,
    H = 72,
    I = 73,
    J = 74,
    K = 75,
    L = 76,
    M = 77,
    N = 78,
    O = 79,
    P = 80,
    Q = 81,
    R = 82,
    S = 83,
    T = 84,
    U = 85,
    V = 86,
    W = 87,
    X = 88,
    Y = 89,
    Z = 90,
    LeftBracket = 91,
    Backslash = 92,
    RightBracket = 93,
    GraveAccent = 96,
    Escape = 256,
    Enter = 257,
    Tab = 258,
    Backspace = 259,
    Insert = 260,
    Delete = 261,
    Right = 262,
    Left = 263,
    Down = 264,
    Up = 265,
    PageUp = 266,
    PageDown = 267,
    Home = 268,
    End = 269,
    CapsLock = 280,
    ScrollLock = 281,
    NumLock = 282,
    PrintScreen = 283,
    Pause = 284,
    F1 = 290,
    F2 = 291,
    F3 = 292,
    F4 = 293,
    F5 = 294,
    F6 = 295,
    F7 = 296,
    F8 = 297,
    F9 = 298,
    F10 = 299,
    F11 = 300,
    F12 = 301,
    LeftShift = 340,
    LeftControl = 341,
    LeftAlt = 342,
    LeftSuper = 343,
    RightShift = 344,
    RightControl = 345,
    RightAlt = 346,
    RightSuper = 347
}

/** 
 * Mouse button constants.
 */
enum Mouse
{
    Left = 0,
    Right = 1,
    Middle = 2,
    Button4 = 3,
    Button5 = 4,
    Button6 = 5,
    Button7 = 6,
    Button8 = 7
}

/** 
 * Some RGBA colour.
 */
struct Color
{
    float r, g, b, a;
}

/** 
 * A texture resource.
 */
struct Texture
{
    uint id;
    int width, height;
}

/** 
 * A sprite frame from a spritesheet.
 */
struct SpriteFrame
{
    float x, y, width, height;
}

/** 
 * A sprite component for rendering textures.
 */
struct Sprite
{
    Texture* texture;
    SpriteFrame frame = SpriteFrame(0, 0, 1, 1);
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
    Sprite* sprite;
    Color color = Color(1, 1, 1, 1);
    bool active = true;
}

/** 
 * Poll for events.
 */
void pollEvents()
{
    glfwPollEvents();
}

alias GameWindow = GLFWwindow;

/** 
 * Should the game window close?
 * 
 * Params:
 *   gw = The game window.
 *
 * Returns: Whether or not it should close
 */
bool shouldClose(GameWindow* gw) => glfwWindowShouldClose(gw) != 0;

/** 
 * Get the current game time.
 *
 * Returns: The current game time as a double.
 */
double getTime() => glfwGetTime();

/** 
 * Get some keypress.
 *
 * Params:
 *   gw = The game window.
 *   keyCode = The current key.
 *
 * Returns: GLFW_PRESS or not. 
 */
ulong getKey(GameWindow* gw, int keyCode) => glfwGetKey(gw, keyCode);

/** 
 * Get some mouse button press.
 *
 * Params:
 *   gw = The game window. 
 *   mbCode = The current mouse button.
 *
 * Returns: GLFW_PRESS or not. 
 */
ulong getMouseButton(GameWindow* gw, int mbCode) => glfwGetMouseButton(gw, mbCode);

/** 
 * Get the position of the mouse cursor.
 *
 * Params:
 *   window = The game window.
 *   x = X position to read the value into
 *   y = Y position to read the value into
 */
void getCursorPosition(GameWindow* window, double* x, double* y)
{
    glfwGetCursorPos(window, x, y);
}

/** 
 * Set background to some color.
 *
 * Params:
 *   r = Red
 *   b = Blue
 *   g = Green
 *   a = Alpha
 */
void clearColor(float r, float b, float g, float a)
{
    glClearColor(r, g, b, a);
}

/** 
 * Clear buffers to preset values.
 *
 * Params:
 *   bb = Bitfield mask 
 */
void clear(BufferBit bb)
{
    glClear(bb);
}

/** 
 * OpenGL bitmask constant.
 */
enum BufferBit
{
    Color = 0x00004000,
    Depth = 0x00000100,
    Stencil = 0x00000400
}

/** 
 * Swap the front and back buffers of the specified window.
 *
 * Params:
 *   gw = The game engine window 
 */
void swapBuffers(GameWindow* gw)
{
    glfwSwapBuffers(gw);
}

/** 
 * Key callback.
 *
 * Params:
 *   window = The game engine window 
 *   key = The key
 *   scancode = The scan code
 *   action = The action
 *   mods = The modifiers
 */
extern (C) void keyCallback(GLFWwindow* window, int key, int scancode, int action, int mods) nothrow
{
    try
    {
        Nova* engine = cast(Nova*) glfwGetWindowUserPointer(window);
        if (engine && key >= 0 && key < 512)
        {
            if (action == GLFW_PRESS)
            {
                if (!engine.input.keys[key])
                    engine.input.keysPressed[key] = true;
                engine.input.keys[key] = true;
            }
            else if (action == GLFW_RELEASE)
            {
                engine.input.keys[key] = false;
                engine.input.keysReleased[key] = true;
            }
        }
    }
    catch (Exception)
    {
        import std.conv;

        writeln("Key callback failed for key with ID " ~ to!string(key));
    }
}

/** 
 * Mouse button callback function.
 *
 * Params:
 *   window = The game engine window.
 *   button = The button
 *   action = The action
 *   mods = The modifiers
 */
extern (C) void mouseButtonCallback(GLFWwindow* window, int button, int action, int mods) nothrow
{
    try
    {
        Nova* engine = cast(Nova*) glfwGetWindowUserPointer(window);
        if (engine && button >= 0 && button < 8)
        {
            if (action == GLFW_PRESS)
            {
                if (!engine.input.mouseButtons[button])
                    engine.input.mousePressed[button] = true;
                engine.input.mouseButtons[button] = true;
            }
            else if (action == GLFW_RELEASE)
            {
                engine.input.mouseButtons[button] = false;
                engine.input.mouseReleased[button] = true;
            }
        }
    }
    catch (Exception)
    {
        import std.conv;

        writeln("Button callback failed for button with ID " ~ to!string(button));
    }
}

extern (C) void cursorPosCallback(GLFWwindow* window, double xpos, double ypos) nothrow
{
    try
    {
        Nova* engine = cast(Nova*) glfwGetWindowUserPointer(window);
        Vec2 newPos = Vec2(cast(float) xpos, cast(float) ypos);
        engine.input.mouseDelta = Vec2(newPos.x - engine.lastMousePos.x,
                newPos.y - engine.lastMousePos.y);
        engine.input.mousePos = newPos;
        engine.lastMousePos = newPos;
    }
    catch (Exception)
    {
    }
}

extern (C) void scrollCallback(GLFWwindow* window, double xoffset, double yoffset) nothrow
{
    try
    {
        Nova* engine = cast(Nova*) glfwGetWindowUserPointer(window);
        engine.input.scrollDelta = Vec2(cast(float) xoffset, cast(float) yoffset);
    }
    catch (Exception)
    {
    }
}

/** 
 * The main renderer of the game.
 *
 * This is the heart of any game built with Nova.
 */
struct Renderer
{
    uint shaderProgram, spriteShader, rectVAO, rectVBO, circleVAO, circleVBO,
        spriteVAO, spriteVBO;

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

        const char* spriteVertexShader = `
            #version 330 core
            layout (location = 0) in vec2 aPos;
            layout (location = 1) in vec2 aTexCoord;
            uniform mat4 transform;
            out vec2 TexCoord;
            void main() {
                gl_Position = transform * vec4(aPos, 0.0, 1.0);
                TexCoord = aTexCoord;
            }`;

        const char* spriteFragmentShader = `
            #version 330 core
            in vec2 TexCoord;
            out vec4 FragColor;
            uniform sampler2D texture1;
            uniform vec4 color;
            void main() {
                FragColor = texture(texture1, TexCoord) * color;
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

        uint svs = glCreateShader(GL_VERTEX_SHADER);
        glShaderSource(svs, 1, &spriteVertexShader, null);
        glCompileShader(svs);

        uint sfs = glCreateShader(GL_FRAGMENT_SHADER);
        glShaderSource(sfs, 1, &spriteFragmentShader, null);
        glCompileShader(sfs);

        spriteShader = glCreateProgram();
        glAttachShader(spriteShader, svs);
        glAttachShader(spriteShader, sfs);
        glLinkProgram(spriteShader);

        glDeleteShader(vs);
        glDeleteShader(fs);
        glDeleteShader(svs);
        glDeleteShader(sfs);

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

        float[] spriteVertices = [
            -0.5f, -0.5f, 0.0f, 1.0f, 0.5f, -0.5f, 1.0f, 1.0f, 0.5f, 0.5f,
            1.0f, 0.0f, -0.5f, 0.5f, 0.0f, 0.0f
        ];

        glGenVertexArrays(1, &spriteVAO);
        glGenBuffers(1, &spriteVBO);
        glBindVertexArray(spriteVAO);
        glBindBuffer(GL_ARRAY_BUFFER, spriteVBO);
        glBufferData(GL_ARRAY_BUFFER, spriteVertices.length * float.sizeof,
                spriteVertices.ptr, GL_STATIC_DRAW);
        glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 4 * float.sizeof, cast(void*) 0);
        glEnableVertexAttribArray(0);
        glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 4 * float.sizeof,
                cast(void*)(2 * float.sizeof));
        glEnableVertexAttribArray(1);

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

    /** 
     * Draw a sprite with optional spritesheet frame.
     *
     * Params:
     *   t = The transform
     *   sprite = The sprite to render
     *   c = The color tint
     */
    void drawSprite(Transform t, Sprite sprite, Color c)
    {
        if (!sprite.texture)
            return;

        glUseProgram(spriteShader);
        glBindTexture(GL_TEXTURE_2D, sprite.texture.id);

        float[16] matrix = [
            t.scale.x, 0, 0, 0, 0, t.scale.y, 0, 0, 0, 0, 1, 0, t.position.x,
            t.position.y, 0, 1
        ];

        float[] vertices = [
            -0.5f, -0.5f, sprite.frame.x,
            sprite.frame.y + sprite.frame.height, 0.5f, -0.5f,
            sprite.frame.x + sprite.frame.width,
            sprite.frame.y + sprite.frame.height, 0.5f, 0.5f,
            sprite.frame.x + sprite.frame.width, sprite.frame.y, -0.5f, 0.5f,
            sprite.frame.x, sprite.frame.y
        ];

        glBindBuffer(GL_ARRAY_BUFFER, spriteVBO);
        glBufferSubData(GL_ARRAY_BUFFER, 0, vertices.length * float.sizeof, vertices.ptr);

        glUniformMatrix4fv(glGetUniformLocation(spriteShader, "transform"), 1, GL_FALSE, matrix.ptr);
        glUniform4f(glGetUniformLocation(spriteShader, "color"), c.r, c.g, c.b, c.a);
        glBindVertexArray(spriteVAO);
        glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    }

    /** 
     * Draw particles from an emitter.
     *
     * Params:
     *   emitter = The particle emitter
     */
    void drawParticles(ParticleEmitter emitter)
    {
        foreach (p; emitter.particles)
        {
            if (p.life > 0)
            {
                Transform t;
                t.position = p.position;
                t.scale = Vec2(p.size, p.size);
                // Simple rect drawing for now
                drawRect(t, p.color);
            }
        }
    }
}

/**
 * A single particle.
 */
struct Particle
{
    Vec2 position;
    Vec2 velocity;
    Color color;
    float size;
    float life = 0;
    float startLife = 0;
    float rotation = 0;
    float rotationSpeed = 0;
}

/**
 * A particle emitter system.
 */
struct ParticleEmitter
{
    Vec2 position;
    Particle[] particles;

    float emissionRate = 0;
    Vec2 velocityMin = Vec2(-1, -1);
    Vec2 velocityMax = Vec2(1, 1);
    Color colorStart = Color(1, 1, 1, 1);
    Color colorEnd = Color(1, 1, 1, 0);
    float lifetimeMin = 1.0f;
    float lifetimeMax = 2.0f;
    float sizeStart = 0.1f;
    float sizeEnd = 0.0f;
    Vec2 gravity = Vec2(0, 0);
    bool active = true;
    bool loop = true;
    float rotationSpeedMin = 0;
    float rotationSpeedMax = 0;

    float emitTimer = 0;

    void update(float dt)
    {
        if (active && emissionRate > 0)
        {
            emitTimer += dt;
            float emitInterval = 1.0f / emissionRate;
            while (emitTimer >= emitInterval)
            {
                burst(1);
                emitTimer -= emitInterval;
            }
        }

        foreach (ref p; particles)
        {
            if (p.life > 0)
            {
                p.life -= dt;
                if (p.life <= 0)
                    continue;

                p.velocity.x += gravity.x * dt;
                p.velocity.y += gravity.y * dt;
                p.position.x += p.velocity.x * dt;
                p.position.y += p.velocity.y * dt;
                p.rotation += p.rotationSpeed * dt;

                float t = 1.0f - (p.life / p.startLife);

                p.color.r = colorStart.r + (colorEnd.r - colorStart.r) * t;
                p.color.g = colorStart.g + (colorEnd.g - colorStart.g) * t;
                p.color.b = colorStart.b + (colorEnd.b - colorStart.b) * t;
                p.color.a = colorStart.a + (colorEnd.a - colorStart.a) * t;

                p.size = sizeStart + (sizeEnd - sizeStart) * t;
            }
        }
    }

    void burst(int count)
    {
        int emitted = 0;
        foreach (ref p; particles)
        {
            if (p.life <= 0)
            {
                p.life = (lifetimeMax > lifetimeMin) ? uniform(lifetimeMin, lifetimeMax)
                    : lifetimeMin;
                p.startLife = p.life;
                p.position = position;

                p.velocity.x = (velocityMax.x > velocityMin.x)
                    ? uniform(velocityMin.x, velocityMax.x) : velocityMin.x;
                p.velocity.y = (velocityMax.y > velocityMin.y)
                    ? uniform(velocityMin.y, velocityMax.y) : velocityMin.y;

                p.color = colorStart;
                p.size = sizeStart;
                p.rotation = uniform(0.0f, 360.0f);
                p.rotationSpeed = (rotationSpeedMax > rotationSpeedMin)
                    ? uniform(rotationSpeedMin, rotationSpeedMax) : rotationSpeedMin;

                emitted++;
                if (emitted >= count)
                    break;
            }
        }
    }
}

/** 
 * The physics engine.
 */
struct Physics
{
    GameObject*[] objects;
    Vec2 gravity = Vec2(0, -0.5f);
    void delegate(GameObject* obj) onGroundHit;

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
                if (obj.rigidbody.velocity.y < 0 && onGroundHit)
                    onGroundHit(obj);

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
    ParticleEmitter*[] particleEmitters;
    Texture*[] textures;
    double lastTime;
    Input input;
    Vec2 lastMousePos;

    /** 
     * Create a particle emitter.
     *
     * Params:
     *   pos = Position of the emitter
     *   maxParticles = Maximum number of particles
     *
     * Returns: Reference to the new particle emitter
     */
    ParticleEmitter* createParticleEmitter(Vec2 pos, int maxParticles)
    {
        ParticleEmitter* emitter = new ParticleEmitter();
        emitter.position = pos;
        emitter.particles.length = maxParticles;
        particleEmitters ~= emitter;
        return emitter;
    }

    /** 
     * Load a texture from a simple PPM file.
     *
     * Params:
     *   filename = Path to the PPM file
     *
     * Returns: Pointer to the loaded texture
     */
    Texture* loadTexture(string filename)
    {
        import std.file : readText;
        import std.conv : to;
        import std.array : split;
        import std.string : strip;

        try
        {
            string content = readText(filename);
            string[] lines = content.split('\n');

            if (lines.length < 4 || lines[0].strip != "P3")
                return null;

            int lineIdx = 1;
            while (lineIdx < lines.length && lines[lineIdx].strip.length == 0)
                lineIdx++;

            string[] dims = lines[lineIdx].strip.split(' ');
            if (dims.length < 2)
                return null;

            int width = dims[0].to!int;
            int height = dims[1].to!int;

            lineIdx++;

            while (lineIdx < lines.length && lines[lineIdx].strip.length == 0)
                lineIdx++;

            lineIdx++;

            ubyte[] pixels;
            for (int i = lineIdx; i < lines.length; i++)
            {
                string[] rgb = lines[i].strip.split(' ');
                foreach (val; rgb)
                {
                    if (val.length > 0)
                        pixels ~= val.to!ubyte;
                }
            }

            Texture* tex = new Texture();
            tex.width = width;
            tex.height = height;

            glGenTextures(1, &tex.id);
            glBindTexture(GL_TEXTURE_2D, tex.id);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB,
                    GL_UNSIGNED_BYTE, pixels.ptr);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

            textures ~= tex;
            return tex;
        }
        catch (Exception e)
        {
            return null;
        }
    }

    /** 
     * Create a spritesheet frame.
     *
     * Params:
     *   x = X position in pixels
     *   y = Y position in pixels  
     *   width = Frame width in pixels
     *   height = Frame height in pixels
     *   texWidth = Total texture width
     *   texHeight = Total texture height
     *
     * Returns: SpriteFrame with UV coordinates
     */
    SpriteFrame createFrame(int x, int y, int width, int height, int texWidth, int texHeight)
    {
        return SpriteFrame(cast(float) x / texWidth, cast(float) y / texHeight,
                cast(float) width / texWidth, cast(float) height / texHeight);
    }

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
        glfwSetWindowUserPointer(window, &this);

        glfwSetKeyCallback(window, &keyCallback);
        glfwSetMouseButtonCallback(window, &mouseButtonCallback);
        glfwSetCursorPosCallback(window, &cursorPosCallback);
        glfwSetScrollCallback(window, &scrollCallback);

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

        double x, y;
        glfwGetCursorPos(window, &x, &y);
        lastMousePos = Vec2(cast(float) x, cast(float) y);
        input.mousePos = lastMousePos;
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
     * Add a sprite to a game object.
     *
     * Params:
     *   obj = The game object
     *   texture = The texture to use
     *   frame = Optional sprite frame (defaults to full texture)
     */
    void addSprite(GameObject* obj, Texture* texture, SpriteFrame frame = SpriteFrame(0, 0, 1, 1))
    {
        obj.sprite = new Sprite();
        obj.sprite.texture = texture;
        obj.sprite.frame = frame;
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
            input.update();

            physics.update(deltaTime);

            glClearColor(0.1f, 0.1f, 0.1f, 1.0f);
            glClear(GL_COLOR_BUFFER_BIT);

            foreach (obj; gameObjects)
            {
                if (obj.active)
                {
                    if (obj.sprite)
                        renderer.drawSprite(obj.transform, *obj.sprite, obj.color);
                    else if (obj.collider && obj.collider.type == Collider.Type.Circle)
                        renderer.drawCircle(obj.transform, obj.color);
                    else
                        renderer.drawRect(obj.transform, obj.color);
                }
            }

            glfwSwapBuffers(window);
        }
    }

    /** 
     * Get the input state for this frame.
     *
     * Returns: Reference to the input system
     */
    ref Input getInput()
    {
        return input;
    }

    /** 
     * Convert screen coordinates to world coordinates.
     *
     * Params:
     *   screenPos = Position in screen coordinates (pixels)
     *
     * Returns: Position in world coordinates
     */
    Vec2 screenToWorld(Vec2 screenPos)
    {
        float aspect = 1920.0f / 1080.0f;
        return Vec2((screenPos.x / 1920.0f - 0.5f) * 2.0f * aspect,
                -(screenPos.y / 1080.0f - 0.5f) * 2.0f);
    }

    /** 
     * Convert world coordinates to screen coordinates.
     *
     * Params:
     *   worldPos = Position in world coordinates
     *
     * Returns: Position in screen coordinates (pixels)
     */
    Vec2 worldToScreen(Vec2 worldPos)
    {
        float aspect = 1920.0f / 1080.0f;
        return Vec2((worldPos.x / aspect / 2.0f + 0.5f) * 1920.0f,
                (-worldPos.y / 2.0f + 0.5f) * 1080.0f);
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
