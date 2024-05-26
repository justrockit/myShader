using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;
using System.Text.RegularExpressions;
using System.Text;
using UnityEditor.ProjectWindowCallback;


	public class HlslShaderTemplate : EditorWindow
	{
    private static string TemplatePath = "Assets/MyShader/Editor/HlslUnlitShader.txt";

    [MenuItem("Assets/Create/Shader/Hlsl/Unlit", false, 208)]
    public static void CreateHlslUnlitShader()
    {
        string tempTxt = string.Empty;
        using (StreamReader sr = new StreamReader(TemplatePath)) tempTxt = sr.ReadToEnd();

        ProjectWindowUtil.StartNameEditingIfProjectWindowExists(0, ScriptableObject.CreateInstance<CreateShaderAction>(), "HlslUnlit", null, tempTxt);
      
    }

    private sealed class CreateShaderAction : EndNameEditAction
    {
        public override void Action(int instanceId, string pathName, string resourceFile)
        {
            var encoding = new UTF8Encoding(encoderShouldEmitUTF8Identifier: true);
            string content = resourceFile;

            pathName += ".shader";
            File.WriteAllText(pathName, content, encoding);

            AssetDatabase.ImportAsset(pathName);
        }
    }

  
   
}
