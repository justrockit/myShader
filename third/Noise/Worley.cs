using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public  class Worley:EditorWindow
{
    static Vector3Int[] neighbours3d = new Vector3Int[]{

    new Vector3Int(0, 0, 0),
    new Vector3Int(1, 0, 0),
    new Vector3Int(0, 1, 0),
    new Vector3Int(1, 1, 0),
    new Vector3Int(-1, 0, 0),
    new Vector3Int(0, -1, 0),
    new Vector3Int(-1, -1, 0),
    new Vector3Int(-1, 1, 0),
    new Vector3Int(1, -1, 0),

    new Vector3Int(0, 0, 1),
    new Vector3Int(1, 0, 1),
    new Vector3Int(0, 1, 1),
    new Vector3Int(1, 1, 1),
    new Vector3Int(-1, 0, 1),
    new Vector3Int(0, -1, 1),
    new Vector3Int(-1, -1, 1),
    new Vector3Int(-1, 1, 1),
    new Vector3Int(1, -1, 1),

    new Vector3Int(0, 0, -1),
    new Vector3Int(1, 0, -1),
    new Vector3Int(0, 1, -1),
    new Vector3Int(1, 1, -1),
    new Vector3Int(-1, 0, -1),
    new Vector3Int(0, -1, -1),
    new Vector3Int(-1, -1, -1),
    new Vector3Int(-1, 1, -1),
    new Vector3Int(1, -1, -1),
};

   public static string path = "Assets/MyShader/myShader/third/Noise/";
    public static Vector3Int shape=new Vector3Int(100,100,100);

    public static int cellsize=1;
    [MenuItem("Tools/Worley3d噪声")]
    private static void generate()
    {
        generate(shape, cellsize);
    }



    private static void generate(Vector3Int shape, int cellsize)
    {

        Vector3Int size = shape * cellsize;
        Texture3D output = new Texture3D(size.x, size.y, size.y, TextureFormat.RGB24, false);
        Vector3[,,] points = generatePoints(shape, cellsize);
        float mapFactor = 1 / Mathf.Sqrt(cellsize * cellsize * 2);

        for (int x = 0; x < shape.x; x++)
        {
            int cellx = x * cellsize;
            for (int y = 0; y < shape.y; y++)
            {
                int celly = y * cellsize;
                for (int z = 0; z < shape.z; z++)
                {
                    Vector3Int cellpos = new Vector3Int(cellx, celly, z * cellsize);

                    for (int i = 0; i < cellsize; i++)
                    {
                        for (int j = 0; j < cellsize; j++)
                        {
                            for (int k = 0; k < cellsize; k++)
                            {
                                Vector3Int pos = new Vector3Int(i, j, k) + cellpos;
                                float v = 0.5f - minDst(pos, getFeaturePoints(points, new Vector3Int(x, y, z), shape, cellsize)) * mapFactor;
                                output.SetPixel(pos.x, pos.y, pos.z, Color.white * v);
                            }
                        }
                    }
                }
            }
        }

        output.Apply();

        // Save the texture to your Unity Project
        AssetDatabase.CreateAsset(output, path+ "testtexture3d.asset");

    }
    public static float minDst(Vector3 pos, Vector3[] buf)
    {
        float dst = Vector3.Distance(pos, buf[0]);
        for (int i = 1; i < buf.Length; i++)
        {
            dst = Mathf.Min(dst, Vector3.Distance(buf[i], pos));
        }
        return dst;
    }
    public static Vector3[] getFeaturePoints(Vector3[,,] pts, Vector3Int pos, Vector3Int shape, int cellSize)
    {

        Vector3 size = new Vector3(shape.x, shape.y, shape.z) * cellSize;
        List<Vector3> buf = new List<Vector3>();
        Vector3Int p;
        Vector3Int fp;
        foreach (Vector3Int offset in neighbours3d)
        {
            p = pos + offset;
            fp = new Vector3Int(
                (p.x + shape.x) % shape.x,
                (p.y + shape.y) % shape.y,
                (p.z + shape.z) % shape.z
            );
            buf.Add(pts[fp.x, fp.y, fp.z] + p * cellSize);
        }
        return buf.ToArray();
    }
    public static Vector3[,,] generatePoints(Vector3Int shape, float cellSize)
    {
        Vector3[,,] output = new Vector3[shape.x, shape.y, shape.z];
        for (int x = 0; x < shape.x; x++)
        {
            float cellx = x * cellSize;
            for (int y = 0; y < shape.y; y++)
            {
                float celly = y * cellSize;
                for (int z = 0; z < shape.z; z++)
                {
                    output[x, y, z] = new Vector3(
                        Random.Range(0, cellSize),
                        Random.Range(0, cellSize),
                        Random.Range(0, cellSize)
                    );
                }
            }
        }
        return output;
    }
}
