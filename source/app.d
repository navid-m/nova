import bindbc.glfw;
import bindbc.opengl;
import std.stdio;

struct GameEngine
{
    GLFWwindow* window;
    bool running;

    void init()
    {
        if (loadGLFW() != glfwSupport)
        {
            writeln("Could not load GLFW");
            return;
        }

        glfwInit();
        glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
        glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);

        window = glfwCreateWindow(1920, 1080, "2D Game Engine".ptr, null, null);
        if (!window)
        {
            glfwTerminate();
            return;
        }

        glfwMakeContextCurrent(window);

        GLSupport glSupport = loadOpenGL();
        if (glSupport == GLSupport.noLibrary)
        {
            writeln("Could not load OpenGL");
            return;
        }

        glViewport(0, 0, 1920, 1080);
        running = true;
    }

    void run()
    {
        while (running && !glfwWindowShouldClose(window))
        {
            glfwPollEvents();

            glClear(GL_COLOR_BUFFER_BIT);

            // Render here

            glfwSwapBuffers(window);
        }
    }

    void cleanup()
    {
        glfwDestroyWindow(window);
        glfwTerminate();
    }
}

void main()
{
    GameEngine engine;
    engine.init();
    engine.run();
    engine.cleanup();
}
