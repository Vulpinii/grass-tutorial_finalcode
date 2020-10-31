#include <stdio.h>
#include <string>
#include <vector>
#include <iostream>
#include <fstream>
#include <algorithm>
#include <sstream>
using namespace std;

#include <stdlib.h>
#include <string.h>

#include <GL/glew.h>

#include "Shader.hpp"

void checkCompileErrors(unsigned int shader, std::string type)
{
        GLint result = GL_FALSE;
        int info_log_length = 1024;
        char * infoLog =  new char[info_log_length];

        if (type != "PROGRAM")
        {
            glGetShaderiv(shader, GL_COMPILE_STATUS, &result);
            if (!result)
            {
                glGetShaderInfoLog(shader, info_log_length, NULL, infoLog);
                std::cout << "ERROR::During compilation of shader " << type << "\n" << infoLog << "\n ******************************** " << std::endl;
            }
        }
        else
        {
            glGetProgramiv(shader, GL_LINK_STATUS, &result);
            if (!result)
            {
                glGetProgramInfoLog(shader, info_log_length, NULL, infoLog);
                std::cout << "ERROR::During link of " << type << "\n" << infoLog << "\n ******************************** " << std::endl;
            }
        }
}

GLuint load_shaders(const char * vertex_file_path,const char * fragment_file_path, const char * geometry_file_path){

        // Create the shaders
        //use glCreateShader()
        unsigned int vertex, fragment, geometry;
        vertex = glCreateShader(GL_VERTEX_SHADER);
        fragment = glCreateShader(GL_FRAGMENT_SHADER);
        if(geometry_file_path != nullptr) geometry = glCreateShader(GL_GEOMETRY_SHADER);
        //**********************/

        // Read the Vertex Shader code from the file
        std::string vertex_shader_code;
        std::ifstream vertex_shader_stream(vertex_file_path, std::ios::in);
        if(vertex_shader_stream.is_open()){
                std::stringstream sstr;
                sstr << vertex_shader_stream.rdbuf();
                vertex_shader_code = sstr.str();
                vertex_shader_stream.close();
        }else{
                printf("Impossible to open %s. Are you in the right directory ? Don't forget to read the FAQ !\n", vertex_file_path);
                getchar();
                return 0;
        }

        // Read the Fragment Shader code from the file
        std::string fragment_shader_code;
        std::ifstream fragment_shader_stream(fragment_file_path, std::ios::in);
        if(fragment_shader_stream.is_open()){
                std::stringstream sstr;
                sstr << fragment_shader_stream.rdbuf();
                fragment_shader_code = sstr.str();
                fragment_shader_stream.close();
        }


        // read the geometry shader code from the file
        std::string geometry_shader_code;
        std::ifstream geometry_shader_stream(geometry_file_path, std::ios::in);
        if(geometry_file_path != nullptr && geometry_shader_stream.is_open()){
            std::stringstream sstr;
            sstr << geometry_shader_stream.rdbuf();
            geometry_shader_code = sstr.str();
            geometry_shader_stream.close();
        }

        // Compile Vertex Shader
        printf("Compiling shader : %s\n", vertex_file_path);
        char const * vertex_source_pointer = vertex_shader_code.c_str();     
        glShaderSource(vertex, 1, &vertex_source_pointer, NULL);
        glCompileShader(vertex);
        // Check Vertex Shader
        checkCompileErrors(vertex, "VERTEX");
        //**********************/


        // Compile Fragment Shader
        printf("Compiling shader : %s\n", fragment_file_path);
        char const * fragment_source_pointer = fragment_shader_code.c_str();
        glShaderSource(fragment, 1, &fragment_source_pointer, NULL);
        glCompileShader(fragment);
        // Check Fragment Shader
        checkCompileErrors(fragment, "FRAGMENT");
        //**********************/

        // Compile Fragment Shader
        char const * geometry_source_pointer ;
        if(geometry_file_path != nullptr)
        {
            printf("Compiling shader : %s\n", geometry_file_path);
            geometry_source_pointer = geometry_shader_code.c_str();
            glShaderSource(geometry, 1, &geometry_source_pointer, NULL);
            glCompileShader(geometry);
            // Check Fragment Shader
            checkCompileErrors(geometry, "GEOMETRY");
        }
        //**********************/


        // Link the program
        printf("Linking program\n");
        GLuint program_ID = glCreateProgram();
        glAttachShader(program_ID, vertex);
        if(geometry_file_path != nullptr) glAttachShader(program_ID, geometry);
        glAttachShader(program_ID, fragment);
        glLinkProgram(program_ID);
        // Check the program
        checkCompileErrors(program_ID, "PROGRAM");
        //**********************/

        glDeleteShader(vertex);
        if(geometry_file_path != nullptr) glDeleteShader(geometry);
        glDeleteShader(fragment);
        //******************************/

        return program_ID;
        //******************************/
}


